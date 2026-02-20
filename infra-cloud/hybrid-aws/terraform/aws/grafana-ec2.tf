data "aws_route53_zone" "main" {
  name         = "nguyentu.online."          
  private_zone = false
}

resource "aws_security_group" "grafana_sg" {
  name        = "riddlebuddy-grafana-sg"
  description = "Allow SSH and Grafana access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  ingress {
    description = "Grafana UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "riddlebuddy-grafana-sg"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

locals {
  amp_datasource = templatefile(
    "${path.module}/datasources/amp.yaml.tpl",
    {
      aws_region        = var.region
      amp_workspace_id  = aws_prometheus_workspace.this.id
    }
  )
}

resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  key_name               = var.key_name
  root_block_device {
    volume_size = 30
    volume_type = "gp3"  
}
  iam_instance_profile = aws_iam_instance_profile.grafana.name
  user_data = templatefile("${path.module}/user_data/grafana.sh", {
    amp_datasource = local.amp_datasource
    dashboard_bucket = aws_s3_bucket.grafana_dashboards.bucket
    hosted_zone_id = data.aws_route53_zone.main.zone_id
  })

  tags = {
    Name    = "riddlebuddy-grafana"
    Project = var.project_name
    Role    = "monitoring"
  }
}
