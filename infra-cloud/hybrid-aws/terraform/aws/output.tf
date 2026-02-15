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

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public.id
}