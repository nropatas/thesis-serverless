data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  subnets      = var.subnets
  vpc_id       = var.vpc_id

  worker_groups = [
    {
      # Updates to these asg capacities will be ignored. Update them on AWS console manually.
      asg_desired_capacity  = var.worker_node_count
      asg_min_size          = var.worker_node_count
      asg_max_size          = var.worker_node_count
      instance_type         = var.worker_instance_type
    }
  ]

  # Remove this line if wget works on your machine
  wait_for_cluster_cmd = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
}
