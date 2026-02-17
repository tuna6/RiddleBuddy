# Add this block somewhere in your root module (e.g. main.tf or remote.tf)
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket         = "riddlebuddy-terraform-state-1"
    key            = "aws/terraform.tfstate"          # ← matches the other workspace's backend key
    region         = "ap-southeast-1"                 # or var.aws_region if you have it
    dynamodb_table = "riddlebuddy-terraform-lock"     # optional, but good to include
    encrypt        = true
  }
}