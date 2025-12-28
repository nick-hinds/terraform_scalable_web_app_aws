output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database.id
}

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "rds_monitoring_role_arn" {
  description = "RDS monitoring role ARN"
  value       = try(aws_iam_role.rds_monitoring[0].arn, "")
}

output "db_password_secret_arn" {
  description = "Database password secret ARN"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_id" {
  description = "Database password secret ID"
  value       = aws_secretsmanager_secret.db_password.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = try(aws_wafv2_web_acl.main[0].arn, "")
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = try(aws_guardduty_detector.main[0].id, "")
}

output "vpc_endpoints_security_group_id" {
  description = "VPC endpoints security group ID"
  value       = try(aws_security_group.vpc_endpoints[0].id, "")
}
