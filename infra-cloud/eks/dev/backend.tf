terraform {
  backend "s3" {
    bucket         = "riddlebuddy-terraform-state-1"
    key            = "eks/dev/terraform.tfstate"   # choose a unique key
    region         = "ap-southeast-1"
    dynamodb_table = "riddlebuddy-terraform-lock"
    encrypt        = true
  }
}