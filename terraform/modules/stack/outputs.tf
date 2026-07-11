output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_data" {
  value = module.eks.cluster_ca_data
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "region_hint" {
  description = "Convenience for building a kubeconfig update command."
  value       = module.eks.cluster_arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "node_group_name" {
  value = module.eks.node_group_name
}

output "managed_addons" {
  value = module.addons.managed_addons
}

output "planted_gotchas_applied" {
  value = module.workloads.planted_gotchas_applied
}
