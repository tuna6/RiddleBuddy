data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "riddlebuddy-terraform-state-1"
    key    = "eks/terraform.tfstate"
    region = "ap-southeast-1"
  }
}