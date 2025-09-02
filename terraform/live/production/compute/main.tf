terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
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

provider "cloudflare" {
  api_token = data.sops_file.secrets.data["cloudflare_api_token"]
}

data "cloudflare_zone" "dump_hr" {
  name = "dump.hr"
}

data "sops_file" "secrets" {
  source_file = "secrets.enc.json"
}

module "web" {
  source = "../../../modules/ec2"

  name_prefix               = "dump-monitoring"
  instance_type             = "t3a.small"
  instance_count            = 1
  instance_root_device_size = 100
  subnets                   = data.aws_subnets.public_subnets.ids
  security_groups           = data.aws_security_groups.public_sg.ids
  ssh_public_key            = file("../../../../ssh-keys/production.pub")
  website_domain            = ["grafana.dump.hr", "prometheus.dump.hr", "loki.dump.hr", "alertmanager.dump.hr", "traefik.dump.hr"]
  cloudflare_zone_id        = data.cloudflare_zone.dump_hr.id

  tags = {
    Project     = "dump-monitoring"
    Role        = "monitoring"
    Environment = "production"
  }
}
