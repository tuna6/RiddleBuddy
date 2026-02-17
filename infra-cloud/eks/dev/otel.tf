resource "helm_release" "otel" {
  name       = "otel-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.108.0" 
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  wait          = true
  wait_for_jobs = true
  timeout       = 600 
  values = [
    file("${path.module}/values.yaml"),   # your main static config (receivers, pipelines, sigv4auth extension, etc.)

    yamlencode({
      serviceAccount = {
        create      = true
        name        = "otel-sa"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.otel_irsa_role.arn
        }
      }

      config = {
        extensions = {
          sigv4auth = {
            region  = var.aws_region
            service = "aps"
          }
        }
        exporters = {
          prometheusremotewrite = {
            endpoint                         = "https://aps-workspaces.${var.aws_region}.amazonaws.com/workspaces/${data.terraform_remote_state.network.outputs.amp_workspace_id}/api/v1/remote_write"
            resource_to_telemetry_conversion = { enabled = true }
            auth                             = { authenticator = "sigv4auth" }
          }
        }
      }
    })
  ]

  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    aws_iam_role.otel_irsa_role
  ]
}

