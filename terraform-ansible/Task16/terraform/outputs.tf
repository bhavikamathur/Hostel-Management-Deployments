output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "web_public_ip_1" {
  description = "Public IP of Web Server 1"
  value       = aws_instance.web_server_1.public_ip
}

output "web_public_ip_2" {
  description = "Public IP of Web Server 2"
  value       = aws_instance.web_server_2.public_ip
}

output "db_private_ip_1" {
  description = "Private IP of DB Server 1"
  value       = aws_instance.db_1.private_ip
}

output "db_private_ip_2" {
  description = "Private IP of DB Server 2"
  value       = aws_instance.db_2.private_ip
}