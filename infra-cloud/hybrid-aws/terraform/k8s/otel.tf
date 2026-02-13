resource "helm_release" "otel" {
  name       = "otel"
  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.otel_aws_creds,
    kubernetes_manifest.clusterrole,
    kubernetes_manifest.clusterrolebinding
  ]
}