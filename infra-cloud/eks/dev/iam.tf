
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