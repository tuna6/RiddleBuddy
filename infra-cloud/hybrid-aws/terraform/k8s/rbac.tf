resource "kubernetes_manifest" "rbac" {
  manifest = yamldecode(file("${path.module}/otel-rbac.yaml"))
}