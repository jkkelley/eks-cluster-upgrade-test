#!/usr/bin/env python3
"""Clean up out-of-band AWS resources before `terraform destroy`.

Kubernetes creates AWS resources Terraform doesn't know about - EBS volumes
dynamically provisioned through PVCs (the aws-ebs-csi-driver), and any EBS
snapshots taken during the backup drill. `make down` destroys the Terraform
stack but leaves those behind, silently billing forever. This script runs as
part of `make down`, before the destroy, and removes them.

Three passes, loudest-possible reporting (nothing is skipped silently):

  1. kubectl pass (only works while the cluster is still up): delete every PVC
     in the cluster and wait for the CSI driver to delete the backing volumes.
     This is the correctly-scoped path - the driver only touches its own disks.
  2. Volume sweep (AWS side): delete leftover CSI-provisioned volumes that are
     `available` and tagged kubernetes.io/created-for/pvc/namespace=<gauntlet ns>.
     Other clusters' CSI volumes are listed as warnings, never auto-deleted.
  3. Snapshot sweep: delete self-owned snapshots tagged
     Purpose=eks-upgrade-gauntlet.

CONVENTION this enforces: any snapshot created during the backup drill MUST be
tagged `Purpose=eks-upgrade-gauntlet`, or this script will not find it.

Usage:
  python3 scripts/teardown_orphans.py <dev|prod>

Exit codes: 0 = clean (or nothing found); 1 = something was found that could
not be cleaned up - the leftovers and manual commands are printed.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
BOOT = REPO / "scripts" / "bootstrap.py"

# The namespace the planted manifests use (manifests/00-namespace.yaml).
# Volume sweep only auto-deletes CSI volumes provisioned for PVCs in this
# namespace, so other clusters in the account are never touched.
GAUNTLET_NAMESPACE = "upgrade-gauntlet"

# Snapshots made during the backup drill must carry this tag (matches the
# Purpose tag Terraform puts on every resource in this project).
SNAPSHOT_TAG_KEY = "Purpose"
SNAPSHOT_TAG_VALUE = "eks-upgrade-gauntlet"

PVC_DELETE_TIMEOUT_S = 180


def log(msg: str) -> None:
    print(f"teardown-orphans: {msg}", file=sys.stderr)


def run(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def bootstrap_print(env: str, key: str) -> str:
    out = run([sys.executable, str(BOOT), env, "--print", key])
    return out.stdout.strip().strip('"')


def kube_context_for(cluster_name: str) -> str | None:
    """Find a kubeconfig context pointing at this cluster (EKS context names
    end in `cluster/<name>`), or None if kubectl/context is unavailable."""
    try:
        out = run(["kubectl", "config", "get-contexts", "-o", "name"], check=False)
    except FileNotFoundError:
        return None
    for ctx in out.stdout.split():
        if ctx.endswith(f"cluster/{cluster_name}") or ctx == cluster_name:
            return ctx
    return None


def kubectl_pass(cluster_name: str) -> bool:
    """Delete all PVCs so the CSI driver deletes its own volumes.
    Returns False if PVCs were found but could not be fully cleaned."""
    ctx = kube_context_for(cluster_name)
    if ctx is None:
        log(f"no kubeconfig context for cluster '{cluster_name}' - skipping kubectl pass")
        return True

    kubectl = ["kubectl", "--context", ctx, "--request-timeout", "15s"]
    got = run(kubectl + ["get", "pvc", "-A", "-o", "json"], check=False)
    if got.returncode != 0:
        log(f"cluster unreachable via context '{ctx}' - skipping kubectl pass")
        return True

    pvcs = json.loads(got.stdout).get("items", [])
    if not pvcs:
        log("kubectl pass: no PVCs in the cluster")
        return True

    names = [f"{p['metadata']['namespace']}/{p['metadata']['name']}" for p in pvcs]
    log(f"kubectl pass: deleting {len(names)} PVC(s): {', '.join(names)}")
    run(kubectl + ["delete", "pvc", "--all", "-A", "--wait=false"], check=False)

    deadline = time.time() + PVC_DELETE_TIMEOUT_S
    while time.time() < deadline:
        left = json.loads(
            run(kubectl + ["get", "pv", "-o", "json"], check=False).stdout or '{"items": []}'
        )["items"]
        csi_left = [
            pv for pv in left
            if (pv["spec"].get("csi") or {}).get("driver") == "ebs.csi.aws.com"
        ]
        if not csi_left:
            log("kubectl pass: all CSI-backed PVs are gone (volumes deleted by the driver)")
            return True
        time.sleep(5)

    log(f"kubectl pass: TIMED OUT after {PVC_DELETE_TIMEOUT_S}s waiting for PV deletion")
    return False


def aws(env_region: str, profile_args: list[str], *args: str) -> dict:
    out = run(["aws", *args, "--region", env_region, "--output", "json", *profile_args])
    return json.loads(out.stdout or "{}")


def volume_sweep(region: str, profile_args: list[str]) -> tuple[list[str], list[str]]:
    """Delete leftover available CSI volumes scoped to the gauntlet namespace.
    Returns (deleted_ids, stranded_descriptions)."""
    scoped = aws(
        region, profile_args, "ec2", "describe-volumes", "--filters",
        f"Name=tag:kubernetes.io/created-for/pvc/namespace,Values={GAUNTLET_NAMESPACE}",
        "Name=status,Values=available",
    ).get("Volumes", [])

    deleted = []
    for vol in scoped:
        vid = vol["VolumeId"]
        log(f"volume sweep: deleting {vid} ({vol['Size']} GiB, {vol['AvailabilityZone']})")
        run(["aws", "ec2", "delete-volume", "--volume-id", vid,
             "--region", region, *profile_args])
        deleted.append(vid)

    # Any other unattached CSI volume in the region: report, never auto-delete
    # (could belong to another cluster in this account).
    others = aws(
        region, profile_args, "ec2", "describe-volumes", "--filters",
        "Name=tag:ebs.csi.aws.com/cluster,Values=true",
        "Name=status,Values=available",
    ).get("Volumes", [])
    stranded = [
        f"{v['VolumeId']} ({v['Size']} GiB) - not scoped to this project; "
        f"delete manually if yours: aws ec2 delete-volume --volume-id {v['VolumeId']} --region {region}"
        for v in others if v["VolumeId"] not in deleted
    ]
    return deleted, stranded


def snapshot_sweep(region: str, profile_args: list[str]) -> list[str]:
    snaps = aws(
        region, profile_args, "ec2", "describe-snapshots", "--owner-ids", "self",
        "--filters", f"Name=tag:{SNAPSHOT_TAG_KEY},Values={SNAPSHOT_TAG_VALUE}",
    ).get("Snapshots", [])

    deleted = []
    for snap in snaps:
        sid = snap["SnapshotId"]
        log(f"snapshot sweep: deleting {sid} ({snap.get('Description') or 'no description'})")
        run(["aws", "ec2", "delete-snapshot", "--snapshot-id", sid,
             "--region", region, *profile_args])
        deleted.append(sid)
    return deleted


def main(argv: list[str]) -> int:
    if len(argv) != 1 or argv[0] not in ("dev", "prod"):
        sys.exit("usage: teardown_orphans.py <dev|prod>")
    env = argv[0]

    project = bootstrap_print(env, "project")
    environment = bootstrap_print(env, "environment")
    region = bootstrap_print(env, "aws_region")
    profile = bootstrap_print(env, "aws_profile")
    profile_args = ["--profile", profile] if profile else []
    cluster_name = f"{project}-{environment}"

    log(f"cleaning out-of-band resources for cluster '{cluster_name}' in {region}")

    ok = kubectl_pass(cluster_name)
    deleted_vols, stranded = volume_sweep(region, profile_args)
    deleted_snaps = snapshot_sweep(region, profile_args)

    log(f"summary: {len(deleted_vols)} volume(s) deleted, "
        f"{len(deleted_snaps)} snapshot(s) deleted, {len(stranded)} stranded")
    for line in stranded:
        log(f"  STRANDED: {line}")

    if not ok:
        log("PVC cleanup did not finish - check `kubectl get pv` and the EC2 "
            "console for volumes still attached, then re-run this script.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
