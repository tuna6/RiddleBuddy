resource "kubernetes_secret" "otel_aws_creds" {
  metadata {
    name      = "otel-aws-creds"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  type = "Opaque"

  string_data = {
    AWS_REGION            = "ap-southeast-1"
    AMP_WORKSPACE_ID      = data.terraform_remote_state.aws.outputs.amp_workspace_id
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  }
}