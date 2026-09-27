terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.3"
}

# Configure the AWS Provider
provider "aws" {
  region  = "eu-west-2"
  profile = var.running_profile
}

