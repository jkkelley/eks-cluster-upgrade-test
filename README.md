# EKS Cluster Upgrade Gauntlet

A small, cheap, deliberately booby-trapped EKS project for **practising a real Kubernetes upgrade**.

You stand it up in `us-east-2` with Terraform, seed it with landmines, then upgrade it **1.34 → 1.35 → 1.36** and discover - the hard way - everything that has to be checked, updated, and unblocked before and during an EKS upgrade.
It is built to trip you on the gotchas so you feel the pain once here instead of live in prod.
Think of it as an interview-prep dojo and a shared drill for any DevOps engineer.

> **Fly blind first.** The full list of planted gotchas, with detection commands and fixes, is sealed in [`CLUSTER_UPGRADE_ANSWERS.html`](#the-sealed-answer-key). Try to find them yourself before you open it.

---

## 💸 Read this before you build (costs money)

The EKS **control plane costs ~$0.10/hour (~$73/month) the entire time it exists**, pods or not.
A promptly-destroyed test session with the defaults (3× t3.medium **SPOT** + a single NAT gateway) runs about **$1-2 for a few hours**.
After `make down` you are back to ~$0 (a few cents of S3 state).

There are exactly two ways this gets expensive:

1. **Forgetting to destroy it.** A left-running cluster is ~$73-110/month. Run `make down ENV=dev` when you finish.
2. **Drifting onto extended support.** Once a Kubernetes version leaves standard support the control plane jumps to **$0.60/hour (~$438/month)**. That is why the default start version is **1.34**, not 1.33 (whose standard support ends 2026-07-29).

Other line items to know about: NAT gateway (~$0.045/hr), any LoadBalancer you create (~$16/mo), public IPv4 addresses ($0.005/hr each), and CloudWatch control-plane logs ($0.50/GB, left off by default).
**Apply one environment at a time** - `dev` and `prod` together means two control planes.

Kubernetes itself can also create AWS resources Terraform doesn't track - EBS volumes from PVCs, and any snapshots you take during the drill.
`make down` runs `scripts/teardown_orphans.py` before the destroy to delete those (PVCs via kubectl, then a tag-scoped volume/snapshot sweep); snapshots you create must be tagged `Purpose=eks-upgrade-gauntlet` for it to find them.

Nothing here applies to AWS on its own. **You** run every `terraform apply` / `make up`.

---

## What's in here

```
terraform/
  modules/{vpc,eks,addons,workloads,stack}/   # the real implementation
  envs/{dev,prod}/                            # thin consumers of modules/stack
  bootstrap-oidc/                             # one-time GitHub Actions OIDC role
manifests/                                    # the planted gotcha fixtures (make seed)
scripts/config.example.toml                   # ← single source of truth (copy to config.toml)
scripts/bootstrap.py                          # reads config, generates tfvars, runs terraform
scripts/serve-answers.{sh,ps1}                # local viewer for the answer key
.github/workflows/                            # terraform plan (PR) + apply (gated, OIDC)
.claude/skills/container-sandbox/             # vendored testing skill (ministack)
Makefile                                      # up / down / plan / apply / seed / serve-answers
Makefile.test                                 # static checks + ministack sandbox
CLUSTER_UPGRADE_ANSWERS.html                  # 🔒 sealed answer key (dark mode + light toggle)
```

Every Terraform variable has **no default** - values come from one file, `scripts/config.toml`.
The `envs/` hold **zero resources** and **zero hardcoded values**; they only pass variables into `modules/stack`.

---

## Configuration (single source of truth)

All values live in **`scripts/config.toml`**. There are no defaults in any `variables.tf`.

```bash
cp scripts/config.example.toml scripts/config.toml   # then edit it for your account
```

- `[common]` applies to **both** dev and prod - change it once and both envs get it.
- `[dev]` / `[prod]` hold only the per-env differences (e.g. prod uses `ON_DEMAND` + audit logging).
- `[bootstrap_oidc]` configures the one-time CI role.

`scripts/bootstrap.py` (Python 3.11+) merges `[common]` + the env section, writes `config.auto.tfvars.json` (git-ignored), and runs Terraform. `make`, the ministack tests, and CI all go through it. Skip the copy step and bootstrap falls back to the committed example, so a fresh clone still runs. `scripts/config.example.toml` documents a generic default for every key inline.

---

## Prerequisites

- **Terraform** ≥ 1.6 (built/tested on 1.14.6), **AWS CLI v2**, **kubectl**, **make**, **Python 3.11+** (for the bootstrap).
- Optional: **helm** on your PATH for hands-on work; **podman** for the ministack tests.
- An **AWS profile** (set it under `aws_profile` in the config, or override with `AWS_PROFILE=...`) that can create VPC/EKS/IAM.
- An **S3 bucket for Terraform state** (set `[backend].bucket` + `region` in the config) with S3-native locking. The bootstrap injects the bucket/region and picks the state key per env (`dev/`, `prod/`, `bootstrap/`), so nothing is hardcoded in `backend.tf`.

---

## Quick start (local Terraform)

```bash
# 1. build the dev cluster (control plane ~15 min)
make up ENV=dev

# 2. point kubectl at it
make kubeconfig ENV=dev

# 3. plant the gotchas
make seed

# 4. hunt. what needs updating/unblocking before you can upgrade?
kubectl get pods -A
kubectl get pdb,validatingwebhookconfigurations -A
kubent            # if installed

# 5. do the upgrade drill (see below), then TEAR DOWN
make down ENV=dev
```

Run against prod by swapping `ENV=prod` (remember: separate control plane, separate cost).

---

## The upgrade drill

The whole point.
The start version is **1.34**; climb one minor at a time and fix what breaks at each step.

```bash
# bump the control plane one minor: edit scripts/config.toml
#   cluster_version = "1.35"
make apply ENV=dev

# reconcile the data plane the CONTROL PLANE just outran (all in scripts/config.toml):
#   - update managed add-ons (kube-proxy first), then CoreDNS, VPC CNI
#   - bump cluster_autoscaler_image_tag to "v1.35.0"
#   - roll the nodes:  node_version = "1.35"  then apply

# validate, then repeat for 1.36
```

What you should hit along the way: add-on version skew, kube-proxy skew, a cluster-autoscaler pinned to the wrong minor, a PodDisruptionBudget that stalls the node drain, a fail-closed webhook, a non-canonical CIDR that 1.36 rejects, a naked pod that never reschedules, the AL2023 / cgroup-v1 / containerd-2.0 runtime changes, and more.
Grade yourself against the answer key.

---

## The sealed answer key

[`CLUSTER_UPGRADE_ANSWERS.html`](CLUSTER_UPGRADE_ANSWERS.html) documents **every** gotcha as Who / What / Where / When / Why, plus a detection command, a fix, and the correct order.
It is dark-mode by default with a light toggle, sectioned for humans, and fully self-contained (works offline).

Open it with a local server (Linux/macOS/WSL or Windows 11):

```bash
make serve-answers          # picks serve-answers.sh or serve-answers.ps1 for your OS
```

It is called an _answer key_ on purpose - **don't read it until you've tried the drill.**

---

## Two ways to deploy

### A) Locally with Terraform

That's the Quick start above (`make up/plan/apply/down`), authenticating with your AWS profile via `AWS_PROFILE`.

### B) GitHub Actions (OIDC, no static keys)

1. **One-time bootstrap** of the CI role (run locally with admin creds; values come from `[bootstrap_oidc]` in the config):
   ```bash
   AWS_PROFILE=<your-admin-profile> python3 scripts/bootstrap.py bootstrap-oidc init -input=false
   AWS_PROFILE=<your-admin-profile> python3 scripts/bootstrap.py bootstrap-oidc apply
   gh variable set AWS_ROLE_ARN \
     --repo "$(python3 scripts/bootstrap.py bootstrap-oidc --print github_owner)/$(python3 scripts/bootstrap.py bootstrap-oidc --print github_repo)" \
     --body "$(python3 scripts/bootstrap.py bootstrap-oidc output -raw role_arn)"
   ```
2. **Plan on PRs** - `terraform-plan.yml` runs `fmt`/`validate` with no AWS, then a real OIDC plan and posts it as a PR comment (per env).
3. **Apply is manual and gated** - run `terraform-apply.yml` via _workflow_dispatch_ (choose `dev`/`prod` and `apply`/`destroy`). Tie the `dev`/`prod` GitHub Environments to required reviewers (Settings → Environments) so an apply needs approval.

---

## Testing (no cloud spend)

Static checks and a **ministack** (local mock-AWS) plan, driven by `Makefile.test` and the vendored [`container-sandbox`](.claude/skills/container-sandbox/SKILL.md) skill.

```bash
make -f Makefile.test test              # fmt-check + validate for both envs (no Docker)
make -f Makefile.test ministack ENV=dev # full terraform plan vs a Podman ministack mock
```

> **Fidelity caveat (important).**
> ministack validates that the **Terraform graph is correct** - it catches wiring, dependency, and attribute bugs across the whole plan/apply for **$0**, and it can even spin up a local k3s so you can practise `kubectl`/`kubent` for free.
> It does **not** faithfully reproduce a live EKS **control-plane version upgrade** or managed-node AMI rotation.
> That realism only exists on real AWS, and driving it is your job - see [The upgrade drill](#the-upgrade-drill).

---

## For other DevOps engineers

This repo is meant to be shared.
Clone it, `make up`, `make seed`, and try to get through the 1.34 → 1.36 climb without opening the answer key.
It doubles as interview prep: the answer key's sections map to the questions that actually get asked about EKS upgrades.
Everything is config-driven, so you can crank the difficulty (more live add-ons, private-vs-public nodes, on-demand vs spot, extra minors) by editing `scripts/config.toml` - never code.
