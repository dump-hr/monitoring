terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "dump-monitoring-tfstate"
    dynamodb_table = "dump-monitoring-tfstate-lock"
    region         = "eu-central-1"
    profile        = "dump-monitoring"
    encrypt        = true
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "dump-monitoring"
}

locals {
  cidr_subnets = cidrsubnets("10.0.0.0/17", 4, 4, 4, 4, 4, 4, 4, 4, 4)
}

module "vpc" {
  source = "../../../modules/vpc"

  name_prefix    = "dump-monitoring"
  vpc_cidr       = "10.0.0.0/17"
  azs            = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  public_subnets = slice(local.cidr_subnets, 0, 3)
  # private_subnets  = slice(local.cidr_subnets, 3, 6)
  # database_subnets = slice(local.cidr_subnets, 6, 9)
  enable_nat_gateway = false

  tags = {
    Project     = "dump-monitoring"
    Environment = "shared"
  }
}
