# Outputs for Complete Infrastructure

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# Security Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = module.security.kms_key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = module.security.kms_key_arn
}

# Compute Outputs
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer Zone ID"
  value       = module.compute.alb_zone_id
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

# Database Outputs
output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.db_instance_endpoint
  sensitive   = true
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = module.database.db_instance_id
}

output "db_read_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = module.database.read_replica_endpoint
  sensitive   = true
}

# Storage Outputs
output "assets_bucket_name" {
  description = "Assets S3 bucket name"
  value       = module.storage.assets_bucket_id
}

output "assets_bucket_arn" {
  description = "Assets S3 bucket ARN"
  value       = module.storage.assets_bucket_arn
}

output "alb_logs_bucket_name" {
  description = "ALB logs S3 bucket name"
  value       = module.storage.alb_logs_bucket_id
}

# Secrets Outputs
output "db_secret_arn" {
  description = "Database password secret ARN"
  value       = module.security.db_password_secret_arn
  sensitive   = true
}

# Monitoring Outputs
output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = module.monitoring.dashboard_url
}

# CDN Outputs
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = try(aws_cloudfront_distribution.main[0].id, "")
}

output "cloudfront_distribution_domain" {
  description = "CloudFront distribution domain name"
  value       = try(aws_cloudfront_distribution.main[0].domain_name, "")
}

# State Management Outputs (if applicable)
output "terraform_state_bucket" {
  description = "Terraform state bucket name"
  value       = try(aws_s3_bucket.terraform_state[0].id, "")
}

output "terraform_lock_table" {
  description = "Terraform lock DynamoDB table name"
  value       = try(aws_dynamodb_table.terraform_lock[0].id, "")
}
