output "grafana_public_ip" {
  description = "Public IP of Grafana EC2"
  value       = aws_instance.grafana.public_ip
}

output "grafana_public_dns" {
  description = "Public DNS of Grafana EC2"
  value       = aws_instance.grafana.public_dns
}

output "grafana_url" {
  description = "Grafana UI URL"
  value       = "http://${aws_instance.grafana.public_dns}:3000"
}

output "amp_workspace_id" {
  value = aws_prometheus_workspace.this.id
}
output "amp_workspace_arn" {
  description = "ARN of the Amazon Managed Prometheus workspace"
  value       = aws_prometheus_workspace.this.arn
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public2.id,
    aws_subnet.public3.id
  ]
}