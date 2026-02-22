module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name               = "riddlebuddy-eks"
  cluster_version = "1.33"        

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids

  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access = true   # nodes use internal
  enable_cluster_creator_admin_permissions = true
  enable_irsa = true
  node_security_group_additional_rules = {
    # ✅ Control plane → Nodes
    ingress_cluster_to_node = {
      description                   = "Allow cluster control plane to nodes"
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # ✅ Nodes → anywhere (internet, EKS API, ECR, S3)
    egress_all = {
      description = "Allow all egress from nodes"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_nlb_http = {
      description = "Allow NLB to nodes on port 80"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
}