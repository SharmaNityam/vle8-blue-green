variable "aws_region" {
  default = "ap-south-1"
}

variable "aws_profile" {
  default = "vle4-lab"
}

variable "instance_type" {
  description = "m7i-flex.large (2 vCPU / 8 GB, free-tier eligible) - Jenkins + Minikube need the headroom"
  default     = "m7i-flex.large"
}

variable "allowed_cidrs" {
  description = "Only these ranges can reach Jenkins and the app"
  type        = list(string)
}
