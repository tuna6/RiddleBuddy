resource "aws_prometheus_workspace" "this" {
  alias = "${var.project_name}-amp"

  tags = {
    Name = "${var.project_name}-amp"
  }
}