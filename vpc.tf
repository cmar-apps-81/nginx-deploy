resource "aws_eip" "nat" {
  count = 1
  vpc   = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = "${var.vpc_name}-eip-${count.index}"
  }
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "172.20.0.0/19"

  azs              = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets   = ["172.20.1.0/24",  "172.20.2.0/24",  "172.20.3.0/24"]
  private_subnets  = ["172.20.4.0/24",  "172.20.5.0/24",  "172.20.6.0/24"]
  database_subnets = ["172.20.7.0/24",  "172.20.8.0/24",  "172.20.9.0/24"]
  intra_subnets    = ["172.20.10.0/24", "172.20.11.0/24", "172.20.12.0/24"]


  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  reuse_nat_ips        = true
  external_nat_ip_ids  = aws_eip.nat.*.id

  tags = {
    Terraform                                   = "true"
    Environment                                 = var.environment
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    Tier                                        = "Public"
    "KubernetesCluster"                         = var.cluster_name
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    Tier                                        = "Private"
    "KubernetesCluster"                         = var.cluster_name
  }

  database_subnet_tags = {
    Tier                                        = "Database"
  }

  intra_subnet_tags = {
    Tier                                        = "Intra"
    "KubernetesCluster"                         = var.cluster_name
  }
}
