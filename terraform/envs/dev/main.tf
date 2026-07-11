locals {
  # manifests/ lives at the repo root, three levels up from terraform/envs/dev.
  manifests_path = abspath("${path.root}/../../../manifests")
}

module "stack" {
  source = "../../modules/stack"

  project         = var.project
  environment     = var.environment
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_cidr             = var.vpc_cidr
  az_count             = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  node_subnet_tier     = var.node_subnet_tier
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_vpc_endpoints = var.enable_vpc_endpoints

  endpoint_public_access    = var.endpoint_public_access
  endpoint_private_access   = var.endpoint_private_access
  public_access_cidrs       = var.public_access_cidrs
  enabled_cluster_log_types = var.enabled_cluster_log_types
  authentication_mode       = var.authentication_mode
  access_entries            = var.access_entries

  node_instance_types  = var.node_instance_types
  capacity_type        = var.capacity_type
  ami_type             = var.ami_type
  node_version         = var.node_version
  node_desired_size    = var.node_desired_size
  node_min_size        = var.node_min_size
  node_max_size        = var.node_max_size
  node_max_unavailable = var.node_max_unavailable
  node_disk_size       = var.node_disk_size

  managed_addons               = var.managed_addons
  addon_versions               = var.addon_versions
  enable_metrics_server        = var.enable_metrics_server
  enable_cluster_autoscaler    = var.enable_cluster_autoscaler
  cluster_autoscaler_image_tag = var.cluster_autoscaler_image_tag
  enable_cert_manager          = var.enable_cert_manager

  enable_planted_gotchas = var.enable_planted_gotchas
  manifests_path         = local.manifests_path

  extra_tags = var.extra_tags
}
