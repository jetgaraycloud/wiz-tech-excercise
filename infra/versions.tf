terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment once you have a state bucket for the CI/CD pipeline to use.
  # Keeping local state for now while you're iterating solo.
  # backend "s3" {
  #   bucket = "wiz-exercise-tfstate-<your-suffix>"
  #   key    = "wiz-exercise/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}
