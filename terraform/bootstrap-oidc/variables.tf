variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "github_owner" {
  type    = string
  default = "jkkelley"
}

variable "github_repo" {
  type    = string
  default = "eks-cluster-upgrade-test"
}

variable "role_name" {
  type    = string
  default = "gha-eks-upgrade-test"
}

variable "subject_claims" {
  description = "Allowed OIDC sub claims. Empty = repo:<owner>/<repo>:* (any branch/env). Tighten to e.g. repo:owner/repo:environment:prod for real use."
  type        = list(string)
  default     = []
}

variable "managed_policy_arns" {
  description = "Policies attached to the CI role. AdministratorAccess by default so the test 'just works' - SCOPE THIS DOWN for anything real."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
