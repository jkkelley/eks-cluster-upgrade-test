provider "aws" {
  region = var.aws_region
  # Profile is intentionally not set here - it comes from the AWS_PROFILE env var
  # (your configured profile locally via the Makefile; unset in CI where OIDC provides creds).
}

# kubectl / helm auth uses the AWS CLI token helper. It inherits AWS_PROFILE / OIDC
# credentials from the environment, so the same config works locally and in CI.
provider "helm" {
  kubernetes {
    host                   = module.stack.cluster_endpoint
    cluster_ca_certificate = base64decode(module.stack.cluster_ca_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.stack.cluster_name, "--region", var.aws_region]
    }
  }
}

provider "kubectl" {
  host                   = module.stack.cluster_endpoint
  cluster_ca_certificate = base64decode(module.stack.cluster_ca_data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.stack.cluster_name, "--region", var.aws_region]
  }
}
