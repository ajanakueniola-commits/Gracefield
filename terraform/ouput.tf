output "vpc_id" {
  value = aws_vpc.grace_vpc.id
}

# output "public_subnet_ids" {
#   value = aws_subnet.public[*].id
# }
output "private_subnet_ids" {
  value = aws_subnet.grace_private[*].id
}
output "db_subnet_group" {
  value = aws_db_subnet_group.grace.name
}
output "security_group_id" {
  value = aws_security_group.grace.id
}
output "ami_used" {
  value = var.ami_id != "" ? var.ami_id : data.aws_ami.packer_or_amazon.id
}
output "instance_type_used" {
  value = var.instance_type
}
output "region_used" {
  value = var.region
}
output "availability_zones_used" {
  value = var.azs
}
output "vpc_cidr_used" {
  value = var.vpc_cidr
}
output "private_subnet_cidrs_used" {
  value = var.private_subnet_cidrs
}
output "backend_public_ips" {
  description = "Public IPs of backend app servers (empty if in private subnet)"
  value       = aws_instance.app[*].public_ip
}
output "web_server_ips" {
  description = "Public IPs of Nginx web servers"
  value       = aws_instance.nginx[*].public_ip
}