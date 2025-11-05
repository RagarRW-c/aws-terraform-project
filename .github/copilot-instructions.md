# AI Agent Instructions for AWS Terraform Project

This document guides AI coding agents on working effectively with this AWS infrastructure-as-code project.

## Project Overview

This is an AWS infrastructure provisioning project using Terraform that creates:
- VPC with public/private subnets across 2 AZs
- EC2 instance running Nginx in public subnet
- RDS PostgreSQL instance in private subnet
- Application Load Balancer
- Security groups and networking components

## Key Files and Their Purposes

- `terraform/main.tf`: Core infrastructure definitions
- `terraform/variables.tf`: Variable definitions (sensitive values handled via tfvars)
- `scripts/user_data.sh`: EC2 instance initialization script
- `terraform.tfvars`: (gitignored) Local variable values
- `.github/workflows/terraform.yml`: CI/CD pipeline

## Project Conventions

### Resource Naming
- All resources are tagged with project name prefix (var.project_name)
- Use `-` as word separator in resource names
- Include resource type in name suffix (e.g., `-vpc`, `-ec2`, `-rds`)

### Network Architecture
- VPC CIDR: 10.0.0.0/16
- Public subnets: 10.0.0.0/24, 10.0.1.0/24
- Private subnets: 10.0.10.0/24, 10.0.11.0/24

### Security Groups
- EC2: Allows inbound 22, 80, 443 from anywhere
- RDS: Allows inbound 5432 only from EC2 security group
- ALB: Allows inbound 80, 443 from anywhere

## Common Development Tasks

### Initial Setup
```bash
# Copy and populate required variables
cp terraform/terraform.tfvars.example terraform.tfvars

# Initialize Terraform
cd terraform
terraform init
```

### Before Making Changes
1. Always work from terraform directory: `cd terraform`
2. Pull latest state: `terraform refresh`
3. Plan changes: `terraform plan`

### Testing Changes
- EC2 user_data changes can be tested by destroying/recreating the instance
- Security group changes take effect immediately
- RDS changes may require maintenance window

## Integration Points

1. EC2 to RDS:
   - Connection details available in Terraform outputs
   - RDS endpoint accessible only from EC2 private IP

2. Load Balancer to EC2:
   - Health check path: "/" (Nginx default page)
   - HTTP on port 80
   - Auto-registers EC2 instance as target

## Common Pitfalls

- Don't modify RDS password directly - use aws_db_instance lifecycle block
- EC2 instance needs key_name variable set for SSH access
- Remember to configure backend S3 for team environments (commented example in main.tf)