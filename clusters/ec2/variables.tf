variable "region" {
  type      = string
  default   = "eu-central-1"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ami" {
  default = "ami-076431be05aaf8080"
}

variable "key_pair_name" {
  default = "sataponn-faastest"
}

variable "private_key_path" {
  default = "~/.ssh/sataponn-faastest.pem"
}
