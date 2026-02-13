resource "aws_iam_role" "grafana" {
  name = "${var.project_name}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "amp_read" {
  name        = "${var.project_name}-amp-read"
  description = "Read-only access to Amazon Managed Prometheus"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.amp_read.arn
}

resource "aws_iam_instance_profile" "grafana" {
  name = "${var.project_name}-grafana-profile"
  role = aws_iam_role.grafana.name
}

resource "aws_iam_role_policy" "grafana_s3" {
  role = aws_iam_role.grafana.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = aws_s3_object.amp_dashboard.arn
      }
    ]
  })
}