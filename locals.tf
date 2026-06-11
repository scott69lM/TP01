# ------------------------------------------------------------------
# locals.tf
# Valeurs calculées réutilisées dans tout le projet. Les CIDR des
# subnets sont générés DYNAMIQUEMENT avec cidrsubnet() : aucun CIDR
# n'est écrit en dur, on dérive tout du vpc_cidr.
# ------------------------------------------------------------------

locals {
  # Préfixe commun de nommage : "formation-dev", "formation-prod", etc.
  name_prefix = "${var.project_name}-${var.environment}"

  # ----------------------------------------------------------------
  # Subnets PUBLICS : map { AZ => CIDR }
  # cidrsubnet("10.0.0.0/16", 8, idx + 1) ajoute 8 bits de masque
  # (=> /24) et incrémente le 3e octet :
  #   idx 0 -> 10.0.1.0/24  (eu-west-3a)
  #   idx 1 -> 10.0.2.0/24  (eu-west-3b)
  # On indexe par AZ pour pouvoir faire un for_each lisible ensuite.
  # ----------------------------------------------------------------
  public_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 1)
  }

  # ----------------------------------------------------------------
  # Subnets PRIVÉS : map { AZ => CIDR }
  # Décalage de 101 pour éviter tout chevauchement avec les publics :
  #   idx 0 -> 10.0.101.0/24 (eu-west-3a)
  #   idx 1 -> 10.0.102.0/24 (eu-west-3b)
  # ----------------------------------------------------------------
  private_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 101)
  }
}
