#!/usr/bin/env python3
"""Bootstrap Terraform from a single config file.

Reads scripts/config.toml (falls back to scripts/config.example.toml), merges
[common] + [<env>], writes the env's config.auto.tfvars.json (which Terraform
auto-loads), then runs terraform. This is the only source of variable values -
there are no defaults in any variables.tf. Change something under [common] and
it applies to both dev and prod.

Log lines go to stderr so `... output -raw <name>` stays clean on stdout.

Usage:
  python3 scripts/bootstrap.py <dev|prod|bootstrap-oidc> [--generate-only] [tf args...]
  python3 scripts/bootstrap.py <env> --print <key>     # emit one merged value

Examples:
  python3 scripts/bootstrap.py dev --generate-only
  python3 scripts/bootstrap.py dev init -input=false
  python3 scripts/bootstrap.py dev plan
  python3 scripts/bootstrap.py dev --print aws_profile
"""
import json
import subprocess
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11
    try:
        import tomli as tomllib  # type: ignore
    except ModuleNotFoundError:
        sys.exit("bootstrap: needs Python 3.11+ (stdlib tomllib) or `pip install tomli`.")

REPO = Path(__file__).resolve().parent.parent
CONFIG = REPO / "scripts" / "config.toml"
CONFIG_EXAMPLE = REPO / "scripts" / "config.example.toml"

ENV_DIRS = {
    "dev": REPO / "terraform" / "envs" / "dev",
    "prod": REPO / "terraform" / "envs" / "prod",
    "bootstrap-oidc": REPO / "terraform" / "bootstrap-oidc",
}
ENV_TABLE = {"dev": "dev", "prod": "prod", "bootstrap-oidc": "bootstrap_oidc"}


def log(msg: str) -> None:
    print(msg, file=sys.stderr)


def deep_merge(base: dict, over: dict) -> dict:
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def load_merged(env: str) -> dict:
    cfg_path = CONFIG if CONFIG.exists() else CONFIG_EXAMPLE
    if not cfg_path.exists():
        sys.exit("bootstrap: no scripts/config.toml or scripts/config.example.toml found")
    if cfg_path == CONFIG_EXAMPLE:
        log("bootstrap: using scripts/config.example.toml (copy it to scripts/config.toml to customize)")
    with open(cfg_path, "rb") as f:
        cfg = tomllib.load(f)
    if env == "bootstrap-oidc":  # standalone: only its own table
        return cfg.get(ENV_TABLE[env], {})
    return deep_merge(cfg.get("common", {}), cfg.get(ENV_TABLE[env], {}))


def main(argv: list[str]) -> int:
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return 0

    env = argv[0]
    rest = argv[1:]
    if env not in ENV_DIRS:
        sys.exit(f"bootstrap: unknown env '{env}' (expected dev | prod | bootstrap-oidc)")

    merged = load_merged(env)
    if not merged:
        sys.exit(f"bootstrap: no config found for env '{env}'")

    # --print <key>: emit one merged value (for Makefile $(shell)); no side effects.
    if rest and rest[0] == "--print":
        if len(rest) < 2:
            sys.exit("bootstrap: --print needs a key")
        val = merged.get(rest[1])
        if val is None:
            sys.exit(f"bootstrap: key '{rest[1]}' not set for env '{env}'")
        sys.stdout.write(val if isinstance(val, str) else json.dumps(val))
        sys.stdout.write("\n")
        return 0

    generate_only = False
    if rest and rest[0] == "--generate-only":
        generate_only = True
        rest = rest[1:]

    out_file = ENV_DIRS[env] / "config.auto.tfvars.json"
    out_file.write_text(json.dumps(merged, indent=2, sort_keys=True) + "\n")
    log(f"bootstrap: wrote {out_file.relative_to(REPO)} ({len(merged)} vars) for env '{env}'")

    if generate_only or not rest:
        if not rest and not generate_only:
            log("bootstrap: tfvars generated; no terraform action requested.")
        return 0

    cmd = ["terraform", f"-chdir={ENV_DIRS[env]}"] + rest
    log("bootstrap: " + " ".join(cmd))
    return subprocess.call(cmd)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
