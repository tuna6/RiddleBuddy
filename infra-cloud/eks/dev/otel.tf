
############################################
# AMP Remote Write Policy
############################################

resource "aws_iam_policy" "amp_remote_write" {
  name = "riddlebuddy-amp-remote-write"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite"
        ]
        Resource = data.terraform_remote_state.network.outputs.amp_workspace_arn
      }
    ]
  })
}

############################################
# IAM Role for OTEL (IRSA)
############################################

resource "aws_iam_role" "otel_irsa_role" {
  name = "riddlebuddy-otel-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:monitoring:otel-sa"
        }
      }
    }]
  })
}

############################################
# Attach Policy to Role
############################################

resource "aws_iam_role_policy_attachment" "attach_amp_policy" {
  role       = aws_iam_role.otel_irsa_role.name
  policy_arn = aws_iam_policy.amp_remote_write.arn
}

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

############################################
# Helm Release
############################################
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
    file("${path.module}/otel-values.yaml"),

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
    aws_iam_role.otel_irsa_role,
    kubernetes_cluster_role_binding.otel
  ]
}

