# No defaults - values are threaded from the stack (ultimately scripts/config.toml).

variable "enable_planted_gotchas" {
  description = "Apply the planted gotcha manifests during terraform apply. Prefer `make seed` and keep this false."
  type        = bool
}

variable "manifests_path" {
  description = "Absolute path to the manifests/ directory holding the planted gotchas."
  type        = string
}
