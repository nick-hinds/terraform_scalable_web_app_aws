locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.additional_tags
  )
  
  # Compute AZ count dynamically
  az_count = length(var.azs)
  
  # Enhanced security settings based on environment
  is_production = var.environment == "prod"
  
  # Enable additional security features in production
  enable_guardduty          = local.is_production
  enable_security_hub       = local.is_production
  enable_config             = local.is_production
  enable_cloudtrail         = local.is_production
  
  # Cost optimization settings
  use_spot_instances = var.enable_cost_optimization && var.environment != "prod"
  
  # Database settings
  db_port = 5432
  
  # S3 bucket name (must be globally unique)
  s3_bucket_name = "${local.name_prefix}-assets-${data.aws_caller_identity.current.account_id}"
  
  # VPC Flow Logs S3 bucket
  flow_logs_bucket_name = "${local.name_prefix}-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}