terraform {
  backend "s3" {
    bucket       = "tf-eks-cluster-upgrade-test"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
