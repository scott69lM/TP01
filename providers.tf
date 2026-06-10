# ------------------------------------------------------------------
# providers.tf
# Déclaration des versions requises et configuration du provider AWS.
# ------------------------------------------------------------------

terraform {
  # On exige Terraform 1.7 minimum (fonctionnalités modernes : validation, etc.)
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Provider AWS v5.x obligatoire pour ce TP
    }
  }
}

# ------------------------------------------------------------------
# Provider AWS
# Les "default_tags" sont appliqués AUTOMATIQUEMENT à toutes les
# ressources qui supportent les tags : pas besoin de les répéter
# sur chaque ressource. Le tag "Owner" est exigé par le compte AWS.
# ------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "tp02-vpc"
      Owner       = "etudiant21"
    }
  }
}
