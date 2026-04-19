variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "staging"
}

variable "instance_type" {
  description = "EC2 instance type for api and payments servers"
  type        = string
  default     = "t2.micro"
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}
