############################################
# Namespace
############################################

resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }

  depends_on = [module.eks]
}

############################################
# CloudWatch Policy
############################################

resource "aws_iam_policy" "fluent_bit_cloudwatch" {
  name = "riddlebuddy-fluent-bit-cloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

############################################
# IAM Role for FluentBit (IRSA)
############################################

resource "aws_iam_role" "fluent_bit_irsa_role" {
  name = "riddlebuddy-fluent-bit-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:logging:fluent-bit"
        }
      }
    }]
  })
}

############################################
# Attach Policy to Role
############################################

resource "aws_iam_role_policy_attachment" "attach_fluent_bit_policy" {
  role       = aws_iam_role.fluent_bit_irsa_role.name
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch.arn
}

############################################
# ClusterRole
############################################

resource "kubernetes_cluster_role" "fluent_bit" {
  metadata {
    name = "fluent-bit"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [module.eks]
}

############################################
# ClusterRoleBinding
############################################

resource "kubernetes_cluster_role_binding" "fluent_bit" {
  metadata {
    name = "fluent-bit"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluent_bit.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "fluent-bit"
    namespace = kubernetes_namespace.logging.metadata[0].name
  }

  depends_on = [module.eks]
}

############################################
# Helm Release
############################################

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.55.0"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [
    file("${path.module}/fluent-bit-values-eks.yaml"),
  ]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.fluent_bit_irsa_role.arn
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.logging,
    aws_iam_role.fluent_bit_irsa_role,
    kubernetes_cluster_role_binding.fluent_bit
  ]
}
