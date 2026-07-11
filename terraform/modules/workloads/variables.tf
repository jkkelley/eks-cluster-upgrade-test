variable "enable_planted_gotchas" {
  description = "Apply the planted gotcha manifests as part of terraform apply. Default off - prefer `make seed` after the cluster is up, so the base infra apply stays free of live-cluster coupling."
  type        = bool
  default     = false
}

variable "manifests_path" {
  description = "Absolute path to the manifests/ directory holding the planted gotchas."
  type        = string
}
