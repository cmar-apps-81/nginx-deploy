aws_region  = "eu-west-1"
aws_profile = "cmar"
environment = "prd"
vpc_name    = "vpc-prd"

cluster_name = "k8s-cmar"
min_nodes    = 2
max_nodes    = 5

nginx_image  = "nginx:1.24.0"
min_replicas = 2
max_replicas = 10
target_group_port = 31647

