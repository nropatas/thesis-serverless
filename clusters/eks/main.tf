provider "aws" {
  profile     = "default"
  region      = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = "eks-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets      = ["10.0.2.0/24", "10.0.4.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/knative"               = "shared"
    "kubernetes.io/cluster/openfaas"              = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/knative"               = "shared"
    "kubernetes.io/cluster/openfaas"              = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "knative" {
  source               = "./modules/eks-cluster"
  cluster_name         = "knative"
  vpc_id               = module.vpc.vpc_id
  subnets              = module.vpc.private_subnets
  worker_node_count    = var.worker_node_count
  worker_instance_type = var.worker_instance_type
}

module "openfaas" {
  source               = "./modules/eks-cluster"
  cluster_name         = "openfaas"
  vpc_id               = module.vpc.vpc_id
  subnets              = module.vpc.private_subnets
  worker_node_count    = var.worker_node_count
  worker_instance_type = var.worker_instance_type
}
