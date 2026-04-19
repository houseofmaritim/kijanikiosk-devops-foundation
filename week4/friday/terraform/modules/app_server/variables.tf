variable "name" {
  description = "The name of the application server, used in tags and resource naming"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "Deployment environment e.g. staging, production"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID in which to launch the instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}
