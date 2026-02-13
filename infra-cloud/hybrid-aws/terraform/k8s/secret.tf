resource "kubernetes_secret_v1" "otel_aws_creds" {
  metadata {
    name      = "otel-aws-creds"
    namespace = "monitoring"
  }

  data = {
    AWS_ACCESS_KEY_ID     = base64encode(var.aws_access_key)
    AWS_SECRET_ACCESS_KEY = base64encode(var.aws_secret_key)
    AWS_REGION = base64encode(var.aws_region)
    AMP_WORKSPACE_ID= base64encode(data.terraform_remote_state.aws.outputs.amp_workspace_id)
  }

  type = "Opaque"
}