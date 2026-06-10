# ------------------------------------------------------------------
# main.tf
# Construction du VPC custom et de tout le réseau associé.
# Aucun module externe : tout est déclaré à la main (mode "custom").
# ------------------------------------------------------------------

# ==================================================================
# 1. VPC
# ==================================================================
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # DNS support + hostnames activés (requis pour résolution interne
  # et pour les endpoints/instances disposant d'un nom DNS).
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ==================================================================
# 2. Internet Gateway (porte de sortie Internet du VPC)
# ==================================================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ==================================================================
# 3. Subnets PUBLICS
# for_each sur la map locals.public_subnets : la clé est l'AZ,
# la valeur est le CIDR. On évite count (pas d'index fragile).
# map_public_ip_on_launch = true : IP publique auto pour les
# instances lancées dans ces subnets.
# ==================================================================
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

# ==================================================================
# 4. Subnets PRIVÉS
# Même logique que les publics, mais sans IP publique automatique :
# la sortie Internet passera par le NAT Gateway.
# ==================================================================
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "${local.name_prefix}-private-${each.key}"
    Tier = "private"
  }
}

# ==================================================================
# 5. Elastic IP pour le NAT Gateway
# Une IP publique fixe attribuée au NAT. domain = "vpc" est la
# syntaxe Provider v5 (remplace l'ancien argument vpc = true).
# ==================================================================
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }

  # L'IGW doit exister avant l'EIP/NAT (bonne pratique de dépendance).
  depends_on = [aws_internet_gateway.this]
}

# ==================================================================
# 6. NAT Gateway (single NAT)
# Un seul NAT pour réduire les coûts (≈ 1 NAT facturé au lieu de 2).
# Placé dans le subnet PUBLIC de la PREMIÈRE AZ (var.azs[0]).
# ==================================================================
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[var.azs[0]].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.this]
}

# ==================================================================
# 7. Route Table PUBLIQUE
# Route par défaut (0.0.0.0/0) dirigée vers l'Internet Gateway.
# ==================================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

# ==================================================================
# 8. Route Table PRIVÉE
# Route par défaut (0.0.0.0/0) dirigée vers le NAT Gateway :
# les subnets privés sortent vers Internet sans être joignables.
# ==================================================================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

# ==================================================================
# 9. Associations Route Table PUBLIQUE
# for_each directement sur la ressource aws_subnet.public :
# on associe chaque subnet public à la route table publique.
# ==================================================================
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ==================================================================
# 10. Associations Route Table PRIVÉE
# ==================================================================
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ==================================================================
# 11. Security Group bastion SSH
# Le SG est volontairement "vide" (pas de bloc ingress/egress en
# ligne) : les règles sont déclarées séparément avec les ressources
# dédiées du Provider v5 (meilleure granularité / moins de conflits).
# ==================================================================
resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "SSH bastion security group"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
  }
}

# Règle INGRESS : SSH (TCP/22) depuis le CIDR autorisé.
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "Autorise le SSH entrant vers le bastion"
  cidr_ipv4         = var.bastion_allowed_cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Règle EGRESS : tout le trafic sortant autorisé vers Internet.
# ip_protocol = "-1" signifie "tous protocoles" ; on ne met alors
# pas de from_port/to_port.
resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  description       = "Autorise tout le trafic sortant"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
