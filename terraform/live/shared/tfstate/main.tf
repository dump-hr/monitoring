terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "dump-monitoring"
}

module "tfstate_backend" {
  source = "github.com/bdeak4/terraform-module-s3-state-backend"

  bucket_name = "dump-monitoring-tfstate"
  table_name  = "dump-monitoring-tfstate-lock"
}
