# Variables du projet (VPC hérité du TP02 + ajouts EC2 du TP03).

variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "project_name" {
  description = "Préfixe de nommage des ressources"
  type        = string
  default     = "scottreboul"
}

variable "vpc_cidr" {
  description = "Bloc CIDR principal du VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit être un CIDR IPv4 valide (ex : 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "Zones de disponibilité utilisées pour les subnets"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "bastion_allowed_cidr" {
  description = "CIDR autorisé pour le SSH sur le bastion"
  type        = string
  default     = "0.0.0.0/0"
}

# Ajouts TP03

variable "instance_type" {
  description = "Type d'instance EC2 (bastion et web)"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Chemin local vers la clé publique SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
