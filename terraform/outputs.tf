output "vpc_id" {
  value = aws_vpc.main.id
}

output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}

output "ec2_instance_id" {
  value = aws_instance.web.id
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  value = aws_db_instance.main.db_name
}

output "connection_command" {
  value = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.web.public_ip}"
}