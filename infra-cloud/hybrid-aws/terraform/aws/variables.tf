variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "grafana_instance_type" {
  description = "EC2 instance type for Grafana"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR for monitoring VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for public subnet"
  type        = string
  default     = "10.30.1.0/24"
}

variable "allowed_ip" {
  description = "IP allowed to access Grafana (your public IP)"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  description = "EC2 SSH key pair name"
}
