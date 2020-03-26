variable "region" {
  type = string
  default = "eu-central-1"
}

variable "worker_node_count" {
  default = 2
}

variable "worker_instance_type" {
  type = string
  default = "t2.small" # m4.large
}
