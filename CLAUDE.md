# CLAUDE.md - eks-cluster-upgrade-test

Agent rules for this repo. This is a **learning/test** project: a deliberately booby-trapped EKS cluster used to practise a Kubernetes upgrade (1.34 → 1.35 → 1.36) in us-east-2.

## What this repo is

A modular Terraform EKS project plus a sealed answer key.
The point is to make an upgrade **hard on purpose** so a human learns the gotchas.
Do not "fix" the planted gotchas in `manifests/` or the intentional lags in the Terraform - they are the curriculum.
The planted items and their fixes are documented in `CLUSTER_UPGRADE_ANSWERS.html`; keep that file in sync if you add or change a gotcha.

## Hard rules

1. **Never run `terraform apply`, `make up/apply`, or otherwise touch real AWS without explicit user approval.** The user drives all applies. Plans and validation are fine.
2. **Config-driven - no defaults, no hardcoding.** Every Terraform variable has NO default; all values live in `scripts/config.toml` (`[common]` applies to both envs, `[dev]`/`[prod]` hold only the diffs). To add a value: put it in the config AND declare the (default-less) variable threaded through env -> `modules/stack` -> the module. Never write a `default =`. Run Terraform through `scripts/bootstrap.py` / `make`, never bare - bare terraform has no variable values.
3. **Test Terraform through ministack.** Any time you write or modify Terraform, validate it via the vendored `container-sandbox` skill (`.claude/skills/container-sandbox/SKILL.md`): `make -f Makefile.test ministack ENV=dev`. `terraform validate` alone is not enough. No real AWS.
4. **Cost discipline.** The control plane bills ~$0.10/hr (or ~$0.60/hr on extended support). Whenever you help the user bring the cluster up, remind them that `make down ENV=<env>` stops the charges, and to apply one env at a time.
5. **One minor at a time.** The upgrade path is 1.34 → 1.35 → 1.36. Never suggest skipping a minor. Control plane first, then add-ons, then nodes.

## Layout

- `terraform/modules/{vpc,eks,addons,workloads}` - implementation (raw AWS resources; transparent for learning).
- `terraform/modules/stack` - composition; the only place the modules are wired together.
- `terraform/envs/{dev,prod}` - thin consumers (backend + providers + one `module "stack"` block; no defaults). Values come from the config via the bootstrap.
- `terraform/bootstrap-oidc` - one-time GitHub Actions OIDC role (config table `[bootstrap_oidc]`).
- `scripts/config.example.toml` - single source of truth template; `scripts/bootstrap.py` merges it and generates each env's tfvars.
- `manifests/` - planted gotcha fixtures, applied with `make seed`.
- `Makefile` (lifecycle) and `Makefile.test` (static + ministack). Cross-OS (Linux + Windows 11).

## Conventions

- Providers: AWS `>= 6.0, < 7.0`, helm `>= 2.12, < 3.0` (nested `set {}` syntax), kubectl (gavinbunney) for planted manifests, tls for OIDC.
- Kube/AWS auth uses `aws eks get-token` via the `AWS_PROFILE` env var, so the same config works locally and in CI (OIDC). Do not hardcode a profile in `backend.tf` or providers.
- State: S3 bucket `tf-eks-cluster-upgrade-test`, keys `dev|prod|bootstrap/terraform.tfstate`, `use_lockfile = true` (no DynamoDB).
- Follow the global markdown rule: one full sentence per line in long Markdown.
- Config: `scripts/config.toml` (real values) is git-ignored; `scripts/config.example.toml` (documented template) is committed. Do not commit `*.tfstate`, `.terraform/`, `config.auto.tfvars.json`, `*.tfvars`, or `.terraform.lock.hcl` (see `.gitignore`).

## Definition of done for changes here

- `make -f Makefile.test test` passes (fmt + validate, both envs).
- If Terraform changed: a ministack plan was attempted and the result reported.
- If a gotcha changed: `CLUSTER_UPGRADE_ANSWERS.html` updated to match.
- No real-AWS side effects unless the user explicitly asked.
