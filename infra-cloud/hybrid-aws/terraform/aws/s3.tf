resource "aws_s3_bucket" grafana_dashboards {
    bucket = "riddle-buddy-dashboards"
    tags = {
        Name    = "grafana-dashboards"
     Project = var.project_name
    }
}

resource "aws_s3_bucket_public_access_block" "grafana_dashboards" {
  bucket = aws_s3_bucket.grafana_dashboards.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "amp_dashboard" {
  bucket = aws_s3_bucket.grafana_dashboards.id
  key    = "riddlebuddy_amp.json"
  source = "${path.module}/dashboards/riddlebuddy_amp.json"
  etag = filemd5("${path.module}/dashboards/riddlebuddy_amp.json")
  content_type = "application/json"
}