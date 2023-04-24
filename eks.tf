module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.6.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = "1.24"
  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  control_plane_subnet_ids        = module.vpc.intra_subnets

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  self_managed_node_group_defaults = {
    instance_type = "t2.micro"

    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    }

    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

  }

  self_managed_node_groups = {
    # Default node group - as provided by AWS EKS
    default_node_group = {

      max_size     = var.max_nodes
      desired_size = var.min_nodes

      # Remote access cannot be specified with a launch template
      key_name = aws_key_pair.terraform.key_name

      default_cooldown          = 60
      health_check_grace_period = 60
      target_group_arns         = [aws_alb_target_group.alb_http.arn]
      bootstrap_extra_args      = "--use-max-pods false"
      
    }
  }

  node_security_group_additional_rules = {
    ingress_source_security_group_id = {
      type                     = "ingress"
      protocol                 = "tcp"
      from_port                = var.target_group_port
      to_port                  = var.target_group_port
      source_security_group_id = aws_security_group.alb.id
    }
  }

  # aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cmar"
      username = "cmar"
      groups   = [""]
    },
  ]

  tags = {
    Environment = var.environment
  }

}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks.cluster_name]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks.cluster_name]
}
