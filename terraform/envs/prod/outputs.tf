output "cluster_name" {
  value = module.stack.cluster_name
}

output "cluster_version" {
  value = module.stack.cluster_version
}

output "cluster_endpoint" {
  value = module.stack.cluster_endpoint
}

output "vpc_id" {
  value = module.stack.vpc_id
}

output "managed_addons" {
  description = "Installed managed add-ons and resolved versions (watch these lag after an upgrade)."
  value       = module.stack.managed_addons
}

output "update_kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --name ${module.stack.cluster_name} --region ${var.aws_region}${var.aws_profile == null ? "" : " --profile ${var.aws_profile}"}"
}
