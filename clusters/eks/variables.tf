variable "region" {
  type = string
  default = "eu-central-1"
}

variable "worker_node_count" {
  default = 1
}

variable "worker_instance_type" {
  type = string
  default = "m4.large"
}
