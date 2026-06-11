# Valeurs utiles pour la vérification (SSH bastion, curl des web).

output "bastion_public_ip" {
  description = "IP publique du bastion"
  value       = aws_eip.bastion.public_ip
}

output "bastion_public_dns" {
  description = "DNS public du bastion"
  value       = aws_instance.bastion.public_dns
}

output "web_private_ips" {
  description = "Map AZ -> IP privée des EC2 web"
  value       = { for k, inst in aws_instance.web : k => inst.private_ip }
}

output "web_instance_ids" {
  description = "Map AZ -> ID instance EC2 web"
  value       = { for k, inst in aws_instance.web : k => inst.id }
}

output "ssh_bastion_command" {
  description = "Commande SSH pour rejoindre le bastion"
  value       = "ssh -i ~/.ssh/id_rsa -A ec2-user@${aws_eip.bastion.public_ip}"
}
