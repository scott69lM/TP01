# Valeurs calculées. Les CIDR des subnets sont dérivés du vpc_cidr.

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Subnets publics : 10.0.1.0/24, 10.0.2.0/24...
  public_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 1)
  }

  # Subnets privés : 10.0.101.0/24, 10.0.102.0/24...
  private_subnets = {
    for idx, az in var.azs : az => cidrsubnet(var.vpc_cidr, 8, idx + 101)
  }

  # Map AZ -> subnet_id privé, utilisée par le for_each des EC2 web.
  web_subnets = { for k, s in aws_subnet.private : k => s.id }
}
