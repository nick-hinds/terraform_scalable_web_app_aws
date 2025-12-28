output "assets_bucket_id" {
  description = "Assets S3 bucket ID"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "Assets S3 bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "assets_bucket_domain_name" {
  description = "Assets S3 bucket domain name"
  value       = aws_s3_bucket.assets.bucket_domain_name
}

output "assets_bucket_regional_domain_name" {
  description = "Assets S3 bucket regional domain name"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}

output "logs_bucket_id" {
  description = "Logs S3 bucket ID"
  value       = try(aws_s3_bucket.logs[0].id, "")
}

output "logs_bucket_arn" {
  description = "Logs S3 bucket ARN"
  value       = try(aws_s3_bucket.logs[0].arn, "")
}

output "alb_logs_bucket_id" {
  description = "ALB logs S3 bucket ID"
  value       = aws_s3_bucket.alb_logs.id
}

output "alb_logs_bucket_arn" {
  description = "ALB logs S3 bucket ARN"
  value       = aws_s3_bucket.alb_logs.arn
}

output "s3_access_policy_arn" {
  description = "S3 access IAM policy ARN"
  value       = aws_iam_policy.s3_access.arn
}
