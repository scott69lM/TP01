# Versions requises et configuration du provider AWS.

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Tags appliqués automatiquement à toutes les ressources.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "tp03-web-ec2"
      Owner       = "etudiant21"
    }
  }
}
