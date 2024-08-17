output "webserver1_public_ip" {
  value = aws_instance.webserver1.public_ip
}

output "webserver2_public_ip" {
  value = aws_instance.webserver2.public_ip
}

output "alb_dns_name" {
  value = aws_lb.myalb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.mydb.endpoint
}
