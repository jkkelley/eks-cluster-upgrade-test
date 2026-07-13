# EKS Upgrade Gauntlet - lifecycle Makefile (Linux + Windows 11).
# Config-driven: every value comes from scripts/config.toml via scripts/bootstrap.py.
# Testing lives in Makefile.test.
#
#   make up ENV=dev            # generate tfvars from config, then init + apply
#   make plan ENV=dev
#   make kubeconfig ENV=dev
#   make seed                  # apply the planted gotcha manifests
#   make down ENV=dev          # destroy everything (DO THIS when done!)
#   make serve-answers         # open the sealed answer key in a browser

ENV ?= dev

# ---- Cross-OS bits ----
ifeq ($(OS),Windows_NT)
  PYTHON        := python
  SERVE_ANSWERS := powershell -NoProfile -ExecutionPolicy Bypass -File scripts/serve-answers.ps1
  DETECTED_OS   := Windows
else
  PYTHON        := python3
  SERVE_ANSWERS := bash scripts/serve-answers.sh
  DETECTED_OS   := $(shell uname -s)
endif

BOOT := $(PYTHON) scripts/bootstrap.py

# Pulled from scripts/config.toml (no hardcoding here). Override on the CLI if needed.
AWS_PROFILE ?= $(shell $(BOOT) $(ENV) --print aws_profile 2>/dev/null)
AWS_REGION  ?= $(shell $(BOOT) $(ENV) --print aws_region 2>/dev/null)
export AWS_PROFILE
export AWS_REGION

.DEFAULT_GOAL := help
.PHONY: help config init plan apply up down output kubeconfig seed unseed serve-answers fmt clean guard-env

help: ## Show this help
	@echo "EKS Upgrade Gauntlet ($(DETECTED_OS)) - ENV=$(ENV), profile=$(AWS_PROFILE), region=$(AWS_REGION)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Config: scripts/config.toml (copy from scripts/config.example.toml). Override env: make plan ENV=prod"

guard-env:
	@case "$(ENV)" in dev|prod) : ;; *) echo "ENV must be dev or prod (got '$(ENV)')"; exit 1;; esac

config: guard-env ## Regenerate the env's tfvars from scripts/config.toml
	$(BOOT) $(ENV) --generate-only

init: guard-env ## Generate tfvars, then terraform init (S3 backend)
	$(BOOT) $(ENV) init -input=false

plan: init ## terraform plan
	$(BOOT) $(ENV) plan

apply: init ## terraform apply (creates AWS resources - COSTS MONEY)
	$(BOOT) $(ENV) apply

up: apply ## Alias for apply

down: guard-env ## terraform destroy (RUN THIS WHEN DONE to stop charges)
	$(BOOT) $(ENV) init -input=false
	-$(PYTHON) scripts/teardown_orphans.py $(ENV)
	$(BOOT) $(ENV) destroy

output: guard-env ## Show terraform outputs
	$(BOOT) $(ENV) output

kubeconfig: guard-env ## Point kubectl at the cluster
	@aws eks update-kubeconfig --name $$($(BOOT) $(ENV) output -raw cluster_name) --region $(AWS_REGION) --profile $(AWS_PROFILE)

seed: ## Apply the planted gotcha manifests to the current kube-context
	kubectl apply -f manifests/

unseed: ## Remove the planted gotcha manifests
	kubectl delete -f manifests/ --ignore-not-found

serve-answers: ## Serve CLUSTER_UPGRADE_ANSWERS.html locally (dark mode, light toggle)
	$(SERVE_ANSWERS)

fmt: ## terraform fmt -recursive
	terraform -chdir=terraform fmt -recursive

clean: ## Remove local terraform caches, generated tfvars, and ministack test artifacts
	find terraform -type d -name ".terraform" -prune -exec rm -rf {} + 2>/dev/null || true
	find terraform -type d -name "test" -prune -exec rm -rf {} + 2>/dev/null || true
	find terraform -name "config.auto.tfvars.json" -delete 2>/dev/null || true
	@echo "cleaned .terraform/, test/, and generated tfvars"
