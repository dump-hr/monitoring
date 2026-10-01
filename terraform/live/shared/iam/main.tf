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

provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
  profile = "dump-monitoring"
}

locals {
  github_repository = "dump-hr/monitoring"
  deploy_branches   = ["main"]

  tags = {
    Project     = "dump-monitoring"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

data "aws_kms_alias" "sops" {
  provider = aws.us-east-1
  name     = "alias/dump-monitoring"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for branch in local.deploy_branches : "repo:${local.github_repository}:ref:refs/heads/${branch}"]
    }
  }
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.sops.target_key_arn]
  }

  statement {
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "github_deploy" {
  name                 = "dump-monitoring-github-deploy"
  assume_role_policy   = data.aws_iam_policy_document.github_deploy_trust.json
  max_session_duration = 3600

  tags = local.tags
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy.json
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy.arn
}
