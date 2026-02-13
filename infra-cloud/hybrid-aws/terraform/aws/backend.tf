terraform {
  backend "s3" {
    bucket         = "riddlebuddy-terraform-state-1"
    key            = "aws/terraform.tfstate"
    region         = "ap-southeast-1"
    use_lockfile = true
    dynamodb_table = "riddlebuddy-terraform-lock"
    encrypt        = true
  }
}