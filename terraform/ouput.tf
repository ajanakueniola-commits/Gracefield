output "nginx_public_ips" {
  description = "Public IPs of NGINX instances"
  value       = aws_instance.nginx[*].public_ip
}

output "app_private_ips" {
  description = "Private IPs of App instances"
  value       = aws_instance.app[*].private_ip
}

# output "jenkins_public_ip" {
#   description = "Public IP of Jenkins"
#   value       = aws_instance.jenkins.public_ip
# }

output "postgres_endpoint" {
  description = "PostgreSQL RDS connection endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "vpc_id" {
  description = "ID of the Grace VPC"
  value       = aws_vpc.grace_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.grace_private[*].id
}

output "vpc_id" {
  value = aws_vpc.grace_vpc.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.grace.name
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.grace.id
}
output "ami_used" {
  description = "AMI ID used for EC2 instances"
  value       = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
}