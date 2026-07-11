terraform {
  backend "s3" {
    bucket = "tf-eks-cluster-upgrade-test"
    key    = "dev/terraform.tfstate"
    region = "us-east-2"

    encrypt = true
    # S3-native locking (Terraform >= 1.10). No DynamoDB table required.
    use_lockfile = true

    # Credentials come from the AWS_PROFILE env var (set by the Makefile to
    # your-aws-profile locally) or from OIDC env credentials in CI. Do NOT hardcode
    # a profile here or CI will break.
  }
}
