resource "helm_release" "otel" {
  name       = "otel"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_secret.otel_aws_creds,
    kubernetes_manifest.rbac
  ]
}