resource "kubernetes_secret_v1" "otel_aws_creds" {
  metadata {
    name      = "otel-aws-creds"
    namespace = "monitoring"
  }

  data = {
    AWS_ACCESS_KEY_ID     = base64encode(var.aws_access_key)
    AWS_SECRET_ACCESS_KEY = base64encode(var.aws_secret_key)
  }

  type = "Opaque"
}