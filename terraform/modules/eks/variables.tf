variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes minor version for the control plane. THE upgrade lever - bump one minor at a time."
  type        = string
  default     = "1.34"
}

variable "subnet_ids" {
  description = "Subnet ids for the control plane cross-account ENIs (usually all subnets)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet ids the managed node group launches into (private or public per node_subnet_tier)."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose the public API endpoint (handy for a test; lock down in real life)."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Enable the private API endpoint."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Default is wide open - a planted 'tighten me' item."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control-plane log types to ship to CloudWatch. Default OFF to save cost - but 'audit' is how you catch deprecated APIs server-side."
  type        = list(string)
  default     = []
}

variable "authentication_mode" {
  description = "Cluster auth mode: CONFIG_MAP (legacy aws-auth), API (access entries only), or API_AND_CONFIG_MAP (both - a planted migration gotcha)."
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Give the Terraform caller cluster-admin via an access entry at create time."
  type        = bool
  default     = true
}

variable "access_entries" {
  description = "Extra IAM principals to grant, keyed by name. Each: principal_arn + policy_arn + access_scope type."
  type = map(object({
    principal_arn = string
    policy_arn    = string
    access_scope  = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
  default = {}
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "SPOT or ON_DEMAND."
  type        = string
  default     = "SPOT"
}

variable "ami_type" {
  description = "Managed node AMI family. AL2 is gone at 1.33+, so default to AL2023."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_version" {
  description = "Kubernetes version for the node group. null = created at cluster version, then it LAGS on upgrade (kubelet-skew lesson). Set explicitly to roll nodes."
  type        = string
  default     = null
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_max_unavailable" {
  description = "Max nodes unavailable during a managed node group rolling update."
  type        = number
  default     = 1
}

variable "node_disk_size" {
  type    = number
  default = 20
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
