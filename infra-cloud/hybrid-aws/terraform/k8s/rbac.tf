resource "kubernetes_manifest" "clusterrole" {
  manifest = yamldecode(file("${path.module}/otel-clusterrole.yaml"))
}

resource "kubernetes_manifest" "clusterrolebinding" {
  manifest = yamldecode(file("${path.module}/otel-clusterrolebinding.yaml"))
}