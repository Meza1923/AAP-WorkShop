output "instance_ids" {
  description = "IDs of the created EC2 instances."
  value       = aws_instance.rhel[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the created EC2 instances."
  value       = aws_instance.rhel[*].public_ip
}

output "instance_private_ips" {
  description = "Private IP addresses of the created EC2 instances."
  value       = aws_instance.rhel[*].private_ip
}

output "instance_names" {
  description = "Name tags of the created EC2 instances."
  value       = [for i in aws_instance.rhel : i.tags["Name"]]
}

output "ami_id_used" {
  description = "AMI ID resolved and used for the instances."
  value       = data.aws_ami.rhel.id
}

output "security_group_id" {
  description = "ID of the security group created for SSH access."
  value       = aws_security_group.ssh.id
}

output "key_pair_name" {
  description = "Name of the AWS key pair created for SSH access."
  value       = aws_key_pair.workshop.key_name
}

output "ansible_inventory_map" {
  description = "Map of instance name to public IP, for building an Ansible inventory."
  value       = { for i in aws_instance.rhel : i.tags["Name"] => i.public_ip }
}
