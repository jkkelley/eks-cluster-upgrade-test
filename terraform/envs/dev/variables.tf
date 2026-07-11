# No defaults anywhere. Every value is supplied by scripts/config.toml via
# scripts/bootstrap.py, which writes config.auto.tfvars.json (git-ignored).
# Run terraform through `make` / the bootstrap script, never bare.

variable "aws_region" { type = string }
variable "aws_profile" {
  description = "For the kubeconfig hint output only; auth uses the AWS_PROFILE env var."
  type        = string
}

variable "project" { type = string }
variable "environment" { type = string }
variable "cluster_version" { type = string }

# ---- networking ----
variable "vpc_cidr" { type = string }
variable "az_count" { type = number }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "node_subnet_tier" { type = string }
variable "enable_nat_gateway" { type = bool }
variable "single_nat_gateway" { type = bool }
variable "enable_vpc_endpoints" { type = bool }

# ---- control plane ----
variable "endpoint_public_access" { type = bool }
variable "endpoint_private_access" { type = bool }
variable "public_access_cidrs" { type = list(string) }
variable "enabled_cluster_log_types" { type = list(string) }
variable "authentication_mode" { type = string }
variable "bootstrap_cluster_creator_admin_permissions" { type = bool }
variable "access_entries" {
  type = map(object({
    principal_arn = string
    policy_arn    = string
    access_scope  = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
}

# ---- node group ----
variable "node_instance_types" { type = list(string) }
variable "capacity_type" { type = string }
variable "ami_type" { type = string }
variable "node_version" { type = string } # "" = created at cluster version, then lags
variable "node_desired_size" { type = number }
variable "node_min_size" { type = number }
variable "node_max_size" { type = number }
variable "node_max_unavailable" { type = number }
variable "node_disk_size" { type = number }

# ---- add-ons ----
variable "managed_addons" { type = list(string) }
variable "addon_versions" { type = map(string) }
variable "addon_resolve_conflicts" { type = string }
variable "enable_metrics_server" { type = bool }
variable "metrics_server_chart_version" { type = string } # "" = latest
variable "enable_cluster_autoscaler" { type = bool }
variable "cluster_autoscaler_chart_version" { type = string } # "" = latest
variable "cluster_autoscaler_image_tag" { type = string }
variable "enable_cert_manager" { type = bool }
variable "cert_manager_chart_version" { type = string } # "" = latest

# ---- planted workloads ----
variable "enable_planted_gotchas" { type = bool }

# ---- tags ----
variable "extra_tags" { type = map(string) }
