# Composition module. No defaults - every value is threaded from the env, which
# gets it from scripts/config.toml. cluster_name is derived (project-environment).

variable "project" { type = string }
variable "environment" { type = string }
variable "cluster_version" { type = string }

# ---- networking ----
variable "vpc_cidr" { type = string }
variable "az_count" { type = number }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "node_subnet_tier" {
  type = string
  validation {
    condition     = contains(["private", "public"], var.node_subnet_tier)
    error_message = "node_subnet_tier must be 'private' or 'public'."
  }
}
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
variable "node_version" { type = string }
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
variable "metrics_server_chart_version" { type = string }
variable "enable_cluster_autoscaler" { type = bool }
variable "cluster_autoscaler_chart_version" { type = string }
variable "cluster_autoscaler_image_tag" { type = string }
variable "enable_cert_manager" { type = bool }
variable "cert_manager_chart_version" { type = string }

# ---- planted workloads ----
variable "enable_planted_gotchas" { type = bool }
variable "manifests_path" { type = string }

# ---- tags ----
variable "extra_tags" { type = map(string) }
