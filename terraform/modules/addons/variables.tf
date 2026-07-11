variable "name_prefix" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  description = "Used to derive default component versions (e.g. the cluster-autoscaler image tag)."
  type        = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer host/path without https:// (for IRSA trust conditions)."
  type        = string
}

variable "node_group_asg_names" {
  description = "ASG names behind the managed node group - tagged for cluster-autoscaler auto-discovery."
  type        = list(string)
  default     = []
}

# ---- EKS-managed add-ons ----
variable "managed_addons" {
  description = "EKS-managed add-ons to install."
  type        = list(string)
  default     = ["vpc-cni", "coredns", "kube-proxy", "aws-ebs-csi-driver", "eks-pod-identity-agent"]
}

variable "addon_versions" {
  description = "Optional explicit add-on versions, keyed by add-on name. Empty = EKS default (which then LAGS the control plane on upgrade - the skew lesson)."
  type        = map(string)
  default     = {}
}

variable "addon_resolve_conflicts" {
  description = "resolve_conflicts_on_create/update for managed add-ons."
  type        = string
  default     = "OVERWRITE"
}

# ---- Helm live subset ----
variable "enable_metrics_server" {
  type    = bool
  default = true
}

variable "metrics_server_chart_version" {
  type    = string
  default = null
}

variable "enable_cluster_autoscaler" {
  type    = bool
  default = true
}

variable "cluster_autoscaler_chart_version" {
  type    = string
  default = null
}

variable "cluster_autoscaler_image_tag" {
  description = "cluster-autoscaler image tag. Pinned to the START minor on purpose - it must track the cluster minor, so after an upgrade this becomes the version-pin gotcha."
  type        = string
  default     = "v1.34.0"
}

variable "enable_cert_manager" {
  type    = bool
  default = false
}

variable "cert_manager_chart_version" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
