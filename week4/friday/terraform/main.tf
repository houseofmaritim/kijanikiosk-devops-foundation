terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

locals {
  servers = {
    api = {
      instance_type = var.instance_type
    }
    payments = {
      instance_type = var.instance_type
    }
    logs = {
      instance_type = "t2.micro"
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name          = "kijanikiosk-${each.key}"
  instance_type = each.value.instance_type
  environment   = var.environment
  ami_id        = "ami-0c55b159cbfafe1d0"
  subnet_id     = "subnet-a39fc806"
  vpc_id        = "vpc-344b7bc4"
}
