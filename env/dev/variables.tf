/*
 * variables.tf
 * Common variables to use in various Terraform files (*.tf)
 */

# The AWS region to use for the dev environment's infrastructure
variable "region" {
  default = "us-west-2"
}

# Tags for the infrastructure
variable "tags" {
  type = map(string)
  default = {
    application = "ejn-devops-app",
    environment = "development",
    team = "devops"
  }
}

variable "devops_api_endpoint" {
  default = ["api.devops.ejntest.com"]
}

variable "devops_ws_api_endpoint" {
  default = ["ws-api.devops.ejntest.com"]
}

variable "vpc_cidr_block" {
  default = "10.92.0.0/16"
}

# The application's name
variable "app" {
  default = "devops"
}

variable "api" {
  default = "devops-api"
}

variable "ws-api" {
  default = "devops-ws-api"
}

# The environment that is being built
variable "environment" {
  default = "development"
}

# The port the container will listen on, used for load balancer health check
# Best practice is that this value is higher than 1024 so the container processes
# isn't running at root.
variable "container_web_port" {
  default = "3000"
}

variable "container_socket_port" {
  default = "9001"
}

# The port the load balancer will listen on
variable "lb_port" {
  default = "80"
}

# The load balancer protocol
variable "lb_protocol" {
  default = "HTTP"
}

# Network configuration
variable "instance_tenancy" {
  default = "default"
}

variable "dns_support" {
  default = true
}

variable "dns_hostnames" {
  default = true
}

variable "destination_cidr_block" {
  default = "0.0.0.0/0"
}

variable "ingress_cidr_block" {
  type = list
  default = [ "0.0.0.0/0" ]
}

variable "egress_cidr_block" {
  type = list
  default = [ "0.0.0.0/0" ]
}

variable "map_public_ip" {
  default = false
}

variable "allowed_management_cidr_blocks" {
  default = [
    // Main Office
    "218.153.127.33/32",
    // Dewey Hong (Home)
    "98.234.161.130/32",
  ]
}
