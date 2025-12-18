
output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "Public ALB DNS"
}

output "web_public_ips" {
  value       = [for i in aws_instance.web : i.public_ip]
  description = "Web instances public IPs"
}

output "web_private_ips" {
  value       = [for i in aws_instance.web : i.private_ip]
  description = "Web instances private IPs"
}

output "db_private_ips" {
  value       = [for i in aws_instance.db : i.private_ip]
  description = "DB instances private IPs"
}

output "primary_db_private_ip" {
  value       = aws_instance.db[0].private_ip
  description = "Use this DB IP for app DB_HOST"
}

