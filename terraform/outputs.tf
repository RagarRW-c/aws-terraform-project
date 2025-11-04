output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# USUŃ te outputy dla starego EC2:
# output "ec2_public_ip" {
#   description = "EC2 instance public IP"
#   value       = aws_instance.web.public_ip
# }

# output "ec2_instance_id" {
#   description = "EC2 instance ID"
#   value       = aws_instance.web.id
# }

# output "connection_command" {
#   description = "SSH connection command"
#   value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.web.public_ip}"
# }

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "alb_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}