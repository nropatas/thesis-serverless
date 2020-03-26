variable "region" {
  type = string
  default = "eu-central-1"
}

variable "cluster_names" {
  type = map
  default = {
    "knative"   = "knative"
    "openfaas"  = "openfaas"
    "openwhisk" = "openwhisk"
    "kubeless"  = "kubeless"
    "fission"   = "fission"
  }
}

variable "worker_instance_type" {
  type = string
  default = "t2.small" # m4.large
}

# variable "client_ip_address" {
#   type = list(string)
#   default = ["0.0.0.0/0"]
# }
