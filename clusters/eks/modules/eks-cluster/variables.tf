variable "cluster_name" {
  type = string
}

variable "vpc_id" {}

variable "subnets" {
  type = list(string)
}

variable "worker_node_count" {}

variable "worker_instance_type" {}
