# EKS Upgrade Gauntlet - lifecycle Makefile (Linux + Windows 11).
# Testing lives in Makefile.test. This file drives real AWS via Terraform.
#
#   make up ENV=dev            # init + apply the dev cluster
#   make plan ENV=dev          # preview
#   make kubeconfig ENV=dev    # point kubectl at it
#   make seed                  # apply the planted gotcha manifests
#   make down ENV=dev          # destroy everything (DO THIS when done!)
#   make serve-answers         # open the sealed answer key in a browser

ENV         ?= dev
AWS_PROFILE ?= your-aws-profile
AWS_REGION  ?= us-east-2
TFDIR       := terraform/envs/$(ENV)
TF          := terraform -chdir=$(TFDIR)

# Export so terraform, the aws CLI, and kubectl token helper all inherit them.
export AWS_PROFILE
export AWS_REGION

# ---- Cross-OS bits ----
ifeq ($(OS),Windows_NT)
  SERVE_ANSWERS := powershell -NoProfile -ExecutionPolicy Bypass -File scripts/serve-answers.ps1
  DETECTED_OS   := Windows
else
  SERVE_ANSWERS := bash scripts/serve-answers.sh
  DETECTED_OS   := $(shell uname -s)
endif

.DEFAULT_GOAL := help
.PHONY: help init plan apply up down output kubeconfig seed unseed serve-answers fmt clean guard-env

help: ## Show this help
	@echo "EKS Upgrade Gauntlet ($(DETECTED_OS)) - ENV=$(ENV), profile=$(AWS_PROFILE), region=$(AWS_REGION)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Override env:   make plan ENV=prod"

guard-env:
	@case "$(ENV)" in dev|prod) : ;; *) echo "ENV must be dev or prod (got '$(ENV)')"; exit 1;; esac

init: guard-env ## terraform init (S3 backend)
	$(TF) init -input=false

plan: init ## terraform plan
	$(TF) plan

apply: init ## terraform apply (creates AWS resources - COSTS MONEY)
	$(TF) apply

up: apply ## Alias for apply

down: guard-env ## terraform destroy (RUN THIS WHEN DONE to stop charges)
	$(TF) init -input=false
	$(TF) destroy

output: guard-env ## Show terraform outputs
	$(TF) output

kubeconfig: guard-env ## Point kubectl at the cluster
	@aws eks update-kubeconfig --name $$($(TF) output -raw cluster_name) --region $(AWS_REGION) --profile $(AWS_PROFILE)

seed: ## Apply the planted gotcha manifests to the current kube-context
	kubectl apply -f manifests/

unseed: ## Remove the planted gotcha manifests
	kubectl delete -f manifests/ --ignore-not-found

serve-answers: ## Serve CLUSTER_UPGRADE_ANSWERS.html locally (dark mode, light toggle)
	$(SERVE_ANSWERS)

fmt: ## terraform fmt -recursive
	terraform -chdir=terraform fmt -recursive

clean: ## Remove local terraform caches and ministack test artifacts
	find terraform -type d -name ".terraform" -prune -exec rm -rf {} + 2>/dev/null || true
	find terraform -type d -name "test" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "cleaned .terraform/ and test/ dirs"
