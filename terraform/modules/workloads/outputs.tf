output "planted_gotchas_applied" {
  description = "How many manifest documents were applied (0 when disabled - use `make seed`)."
  value       = var.enable_planted_gotchas ? length(data.kubectl_path_documents.gotchas.documents) : 0
}
