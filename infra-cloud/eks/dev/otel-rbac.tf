resource "kubernetes_cluster_role" "otel" {
  metadata {
    name = "otel-collector-metrics"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/stats", "nodes/proxy"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics", "/metrics/*"]
    verbs             = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [module.eks]
}

resource "kubernetes_cluster_role_binding" "otel" {
  metadata {
    name = "otel-collector-metrics-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.otel.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "otel-sa"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [module.eks]
}