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

resource "aws_iam_policy" "ssm_read" {
  name        = "${var.project_name}-ssm-read"
  description = "Read-only access to SSM parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect": "Allow",
        "Action": ["ssm:GetParameter"],
        "Resource": [
          "arn:aws:ssm:*:*:parameter/grafana/tls/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "grafana_amp" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.amp_read.arn
}
resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.ssm_read.arn
}
resource "aws_iam_instance_profile" "grafana" {
  name = "${var.project_name}-grafana-profile"
  role = aws_iam_role.grafana.name
}

resource "aws_iam_role_policy" "grafana_s3" {
  name = "${var.project_name}-grafana-s3"
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
resource "aws_iam_policy" "route53_update" {
  name        = "${var.project_name}-route53-update"
  description = "Allow Grafana EC2 to update Route53 A record on boot"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:GetChange"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main.zone_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "grafana_route53" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.route53_update.arn
}