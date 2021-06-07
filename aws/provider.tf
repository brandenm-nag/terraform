terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
    required_version = ">= 0.13.0"
}


provider "aws" {
  shared_credentials_file = var.credentials
  profile     = var.profile  # refer to ~/.aws/credentials
  region      = var.region
}
