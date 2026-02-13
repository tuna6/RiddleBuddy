data "terraform_remote_state" "aws" {
  backend = "s3"

  config = {
    bucket = "riddlebuddy-terraform-state-1"
    key    = "aws/terraform.tfstate"
    region = "ap-southeast-1"
  }
}