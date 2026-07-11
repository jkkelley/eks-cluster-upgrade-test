variable "name_prefix" {
  description = "Prefix for all resource names (e.g. eks-upgrade-dev)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name - used for Kubernetes subnet discovery tags."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Kept small on purpose to make IP-exhaustion a real lesson."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many AZs to spread subnets across."
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ). Small on purpose."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (one per AZ). Small on purpose - VPC CNI hands these IPs to pods."
  type        = list(string)
  default     = ["10.0.16.0/24", "10.0.17.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private nodes have egress. Flip false for the cheapest public-node runs."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway instead of one per AZ (cost saver for a test)."
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create S3 gateway + interface endpoints (ECR/STS/EC2/ELB) as a NAT-free egress lesson."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags merged onto every resource."
  type        = map(string)
  default     = {}
}
