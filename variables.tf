# ------------------------------------------------------------------
# variables.tf
# Toutes les entrées paramétrables du module. Chaque variable a un
# type explicite, une description et (quand c'est pertinent) une
# règle de validation pour bloquer les valeurs invalides au plan.
# ------------------------------------------------------------------

variable "aws_region" {
  description = "Région AWS de déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "dev"

  # On n'autorise que trois valeurs : toute autre valeur fait échouer le plan.
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être l'une des valeurs : dev, staging, prod."
  }
}

variable "project_name" {
  description = "Nom du projet, utilisé comme préfixe de nommage des ressources"
  type        = string
  default     = "scottreboul"
}

variable "vpc_cidr" {
  description = "Bloc CIDR principal du VPC"
  type        = string
  default     = "10.0.0.0/16"

  # cidrnetmask() échoue si la chaîne n'est pas un CIDR IPv4 valide :
  # can() transforme cette erreur en false => message clair.
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit être un bloc CIDR IPv4 valide (ex : 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "Liste des zones de disponibilité utilisées pour les subnets"
  type        = list(string)
  default = [
    "eu-west-3a",
    "eu-west-3b",
  ]
}

variable "bastion_allowed_cidr" {
  description = "CIDR autorisé pour SSH sur le bastion"
  type        = string
  default     = "0.0.0.0/0"
}
