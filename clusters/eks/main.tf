provider "aws" {
  profile     = "default"
  region      = var.region
}

# Networking

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name"                                                  = "eks"
    "kubernetes.io/cluster/${var.cluster_names["knative"]}" = "shared"
  }
}

resource "aws_subnet" "eks_subnets" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.eks_vpc.id

  tags = {
    "Name"                                                  = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_names["knative"]}" = "shared"
  }
}

resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "eks"
  }
}

resource "aws_route_table" "eks" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }
}

resource "aws_route_table_association" "eks" {
  count = 2

  subnet_id      = aws_subnet.eks_subnets[count.index].id
  route_table_id = aws_route_table.eks.id
}

# K8S Master Role

# resource "aws_iam_role" "eks" {
#   name = "eks"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "eks.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks.name
# }

# resource "aws_iam_role_policy_attachment" "eks_AmazonEKSServicePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   role       = aws_iam_role.eks.name
# }

# resource "aws_security_group" "eks" {
#   name        = "eks"
#   description = "Cluster communication with worker nodes"
#   vpc_id      = aws_vpc.eks_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-sg"
#   }
# }

# resource "aws_security_group_rule" "eks-ingress-workstation-https" {
#   cidr_blocks       = var.client_ip_address
#   description       = "Allow workstation to communicate with the cluster API Server"
#   from_port         = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.eks.id
#   to_port           = 443
#   type              = "ingress"
# }

module "knative-cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_names["knative"]
  subnets      = aws_subnet.eks_subnets.*.id
  vpc_id       = aws_vpc.eks_vpc.id

  worker_groups = [
    {
      asg_desired_capacity  = 1
      asg_min_capacity      = 1
      asg_max_capacity      = 1
      instance_type         = var.worker_instance_type
    }
  ]

  wait_for_cluster_cmd = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
}
