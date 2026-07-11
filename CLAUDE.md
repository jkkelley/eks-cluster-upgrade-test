# CLAUDE.md - eks-cluster-upgrade-test

Agent rules for this repo. This is a **learning/test** project: a deliberately booby-trapped EKS cluster used to practise a Kubernetes upgrade (1.34 → 1.35 → 1.36) in us-east-2.

## What this repo is

A modular Terraform EKS project plus a sealed answer key.
The point is to make an upgrade **hard on purpose** so a human learns the gotchas.
Do not "fix" the planted gotchas in `manifests/` or the intentional lags in the Terraform - they are the curriculum.
The planted items and their fixes are documented in `CLUSTER_UPGRADE_ANSWERS.html`; keep that file in sync if you add or change a gotcha.

## Hard rules

1. **Never run `terraform apply`, `make up/apply`, or otherwise touch real AWS without explicit user approval.** The user drives all applies. Plans and validation are fine.
2. **Parameterize everything - do not hardcode.** Region, versions, names, CIDRs, instance types, capacity type, node counts, the NAT toggle, add-on versions, and tags are all variables with defaults. New values become variables in `modules/stack` (and are surfaced in `envs/*/variables.tf`). `envs/` hold zero resources.
3. **Test Terraform through ministack.** Any time you write or modify Terraform, validate it via the vendored `container-sandbox` skill (`.claude/skills/container-sandbox/SKILL.md`): `make -f Makefile.test ministack ENV=dev`. `terraform validate` alone is not enough. No real AWS.
4. **Cost discipline.** The control plane bills ~$0.10/hr (or ~$0.60/hr on extended support). Whenever you help the user bring the cluster up, remind them that `make down ENV=<env>` stops the charges, and to apply one env at a time.
5. **One minor at a time.** The upgrade path is 1.34 → 1.35 → 1.36. Never suggest skipping a minor. Control plane first, then add-ons, then nodes.

## Layout

- `terraform/modules/{vpc,eks,addons,workloads}` - implementation (raw AWS resources; transparent for learning).
- `terraform/modules/stack` - composition; the only place the modules are wired together.
- `terraform/envs/{dev,prod}` - thin consumers (backend + providers + one `module "stack"` block + tfvars).
- `terraform/bootstrap-oidc` - one-time GitHub Actions OIDC role.
- `manifests/` - planted gotcha fixtures, applied with `make seed`.
- `Makefile` (lifecycle) and `Makefile.test` (static + ministack). Cross-OS (Linux + Windows 11).

## Conventions

- Providers: AWS `>= 6.0, < 7.0`, helm `>= 2.12, < 3.0` (nested `set {}` syntax), kubectl (gavinbunney) for planted manifests, tls for OIDC.
- Kube/AWS auth uses `aws eks get-token` via the `AWS_PROFILE` env var, so the same config works locally and in CI (OIDC). Do not hardcode a profile in `backend.tf` or providers.
- State: S3 bucket `tf-eks-cluster-upgrade-test`, keys `dev|prod|bootstrap/terraform.tfstate`, `use_lockfile = true` (no DynamoDB).
- Follow the global markdown rule: one full sentence per line in long Markdown.
- Do not commit `*.tfstate`, `.terraform/`, `*.tfvars`, or `.terraform.lock.hcl` (see `.gitignore`); keep `*.tfvars.example` committed.

## Definition of done for changes here

- `make -f Makefile.test test` passes (fmt + validate, both envs).
- If Terraform changed: a ministack plan was attempted and the result reported.
- If a gotcha changed: `CLUSTER_UPGRADE_ANSWERS.html` updated to match.
- No real-AWS side effects unless the user explicitly asked.
