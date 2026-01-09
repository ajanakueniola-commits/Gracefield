output "alb_dns_name" {
  value = aws_lb.nginx.dns_name
}

output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "postgres_private_ip" {
  value = aws_instance.postgres.private_ip
}

output "vpc_id" {
  value = aws_vpc.grace.id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "autoscaling_group_name" {
  value = aws_autoscaling_group.nginx.name
}
