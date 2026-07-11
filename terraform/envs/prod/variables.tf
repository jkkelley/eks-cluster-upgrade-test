# Every value is a variable. Defaults make `terraform apply` runnable with no tfvars;
# override any of them in dev.tfvars (gitignored) or via TF_VAR_* / -var.

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "aws_profile" {
  description = "For the kubeconfig hint output only. Auth itself uses the AWS_PROFILE env var."
  type        = string
  default     = "your-aws-profile"
}

variable "project" {
  type    = string
  default = "eks-upgrade"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cluster_name" {
  type    = string
  default = null
}

variable "cluster_version" {
  type    = string
  default = "1.34"
}

# ---- Networking ----
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "az_count" {
  type    = number
  default = 2
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.16.0/24", "10.0.17.0/24"]
}
variable "node_subnet_tier" {
  type    = string
  default = "private"
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "single_nat_gateway" {
  type    = bool
  default = true
}
variable "enable_vpc_endpoints" {
  type    = bool
  default = false
}

# ---- Control plane ----
variable "endpoint_public_access" {
  type    = bool
  default = true
}
variable "endpoint_private_access" {
  type    = bool
  default = true
}
variable "public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "enabled_cluster_log_types" {
  type    = list(string)
  default = []
}
variable "authentication_mode" {
  type    = string
  default = "API_AND_CONFIG_MAP"
}
variable "access_entries" {
  type = map(object({
    principal_arn = string
    policy_arn    = string
    access_scope  = optional(string, "cluster")
    namespaces    = optional(list(string), [])
  }))
  default = {}
}

# ---- Node group ----
variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "capacity_type" {
  type    = string
  default = "SPOT"
}
variable "ami_type" {
  type    = string
  default = "AL2023_x86_64_STANDARD"
}
variable "node_version" {
  type    = string
  default = null
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
  type    = number
  default = 1
}
variable "node_disk_size" {
  type    = number
  default = 20
}

# ---- Add-ons ----
variable "managed_addons" {
  type    = list(string)
  default = ["vpc-cni", "coredns", "kube-proxy", "aws-ebs-csi-driver", "eks-pod-identity-agent"]
}
variable "addon_versions" {
  type    = map(string)
  default = {}
}
variable "enable_metrics_server" {
  type    = bool
  default = true
}
variable "enable_cluster_autoscaler" {
  type    = bool
  default = true
}
variable "cluster_autoscaler_image_tag" {
  type    = string
  default = "v1.34.0"
}
variable "enable_cert_manager" {
  type    = bool
  default = false
}

# ---- Planted workloads ----
variable "enable_planted_gotchas" {
  type    = bool
  default = false
}

# ---- Tags ----
variable "extra_tags" {
  type    = map(string)
  default = {}
}
