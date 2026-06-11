# Couche compute du TP03 : AMI, key pair, SG web, bastion, EC2 web.

# AMI Amazon Linux 2023 la plus récente (pas d'ID hardcodé).
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Clé publique SSH locale déposée dans chaque EC2.
resource "aws_key_pair" "formation" {
  key_name   = "${local.name_prefix}-key"
  public_key = file(pathexpand(var.public_key_path))

  tags = {
    Name = "${local.name_prefix}-key"
  }
}

# SG web : SSH/HTTP uniquement depuis le SG bastion, sortie libre.
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Allow SSH/HTTP from bastion SG only"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-web-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id            = aws_security_group.web.id
  description                  = "SSH depuis le bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id            = aws_security_group.web.id
  description                  = "HTTP depuis le bastion"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Sortie libre (updates, nginx)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Bastion : seul point d'entrée SSH, en subnet public AZ-a.
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[var.azs[0]].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.formation.key_name
  associate_public_ip_address = true

  # Le volume racine doit aussi porter Owner (exigé par la policy AWS).
  root_block_device {
    tags = {
      Owner = "etudiant21"
    }
  }

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
  }
}

# IP publique stable du bastion (gratuite tant qu'attachée).
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name = "${local.name_prefix}-bastion-eip"
  }

  depends_on = [aws_internet_gateway.this]
}

# EC2 web : 1 par AZ, nginx installé via user_data templaté.
resource "aws_instance" "web" {
  for_each = local.web_subnets

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.formation.key_name

  user_data = templatefile("${path.module}/templates/nginx.sh.tftpl", {
    az = each.key
  })

  # Recrée l'instance si le user_data change.
  user_data_replace_on_change = true

  # Crée la nouvelle avant de détruire l'ancienne.
  lifecycle {
    create_before_destroy = true
  }

  # Le volume racine doit aussi porter Owner (exigé par la policy AWS).
  root_block_device {
    tags = {
      Owner = "etudiant21"
    }
  }

  tags = {
    Name = "${local.name_prefix}-web-${each.key}"
    Role = "web"
    AZ   = each.key
  }
}
