# ------------------------------------------------------------------
# outputs.tf
# Valeurs exposées après "terraform apply" : utiles pour le débogage
# et pour brancher d'autres modules dessus.
# ------------------------------------------------------------------

output "vpc_id" {
  description = "Identifiant du VPC créé"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Liste des IDs des subnets publics"
  # for sur la map de ressources : on ne récupère que les .id
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Liste des IDs des subnets privés"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "nat_gateway_public_ip" {
  description = "IP publique (Elastic IP) du NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "bastion_security_group_id" {
  description = "ID du Security Group du bastion SSH"
  value       = aws_security_group.bastion.id
}
