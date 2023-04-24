variable "environment" {
  description = "Environment resources belong to"
}

variable "aws_profile" {
  description = "AWS Profile to use"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_name" {
  description = "Vpc name"
}

variable "cluster_name" {
  description = "Cluster name"
}

variable "min_nodes" {
  description = "Min number of nodes"
  default     = 2
}

variable "max_nodes" {
  description = "Max number of nodes"
  default     = 5
}

variable "nginx_image" {
  description = "Nginx container image"
  default     = "nginx:latest"
}

variable "min_replicas" {
  description = "Min number of replicas"
  default     = 2
}

variable "max_replicas" {
  description = "Max number of replicas"
  default     = 10
}

variable "target_group_port" {
  description = ""
}
