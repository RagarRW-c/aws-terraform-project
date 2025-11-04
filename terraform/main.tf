terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }

  /*backend "s3" {
    bucket         = "pearson-terraform-state-9825-3438-5511"
    key            = "dev/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }*/
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Pearson-devops"
      Environment = "var.environment"
      ManagedBY   = "Terraform"
    }
  }
}


#VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

#IGW
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-iwg"
  }
}

#public subnet
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

#private subnet
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

#Route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

}

#SG for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security grooup for EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

#Scurity gorup fro RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "SG fro RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "PostgreSQL access from EC2"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

/*#ec2 instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  user_data = file("${path.module}/../scripts/user_data.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true

  }

  tags = {
    Name = "${var.project_name}-web-server"
  }
}*/

#autoscalling group + launch template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = filebase64("${path.module}/../scripts/user_data.sh")

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-web-server"
    }
  }
}

#auto scalling group
resource "aws_autoscaling_group" "web" {
  name                      = "${var.project_name}-asg"
  vpc_zone_identifier       = aws_subnet.public[*].id
  target_group_arns         = [aws_lb_target_group.main.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "Pearson DevOps"
    propagate_at_launch = true
  }
}

#autoscaling policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

#cloudwatch alarm - high cpu
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Triggers when CPU exceeds 70%"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

#auto scaling policy - scale down
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

#cloudwatch alarm - low cpu
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
  alarm_description = "Triggers when CPU is below 20%"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}



#Application load balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

#Security group for alb
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "security group for application load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http from anywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "https from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

#target group
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

#ALB listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}



#rds subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

#RDS instance
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-postgres-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres-db"
  }
}

#data source
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}