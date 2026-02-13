terraform {
  backend "s3" {
    bucket         = "riddlebuddy-terraform-state-1"
    key            = "cluster/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "riddlebuddy-terraform-lock"
    encrypt        = true
  }

  required_providers {
    aws         = { source = "hashicorp/aws" }
    kubernetes  = { source = "hashicorp/kubernetes" }
    helm        = { source = "hashicorp/helm" }
  }
}