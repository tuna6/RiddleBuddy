data "terraform_remote_state" "aws" {
  backend = "s3"

  config = {
    bucket = "riddlebuddy-terraform-state-1"
    key    = "aws/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
locals {
  amp_remote_write_url = "https://aps-workspaces.ap-southeast-1.amazonaws.com/workspaces/${data.terraform_remote_state.aws.outputs.amp_workspace_id}/api/v1/remote_write"
}
