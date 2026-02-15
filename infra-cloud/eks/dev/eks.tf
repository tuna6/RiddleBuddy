module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.15.1"

  cluster_name    = "riddlebuddy-eks"
  cluster_version = "1.29"

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.micro"]
      min_size       = 2
      max_size       = 2
      desired_size   = 2
    }
  }
}