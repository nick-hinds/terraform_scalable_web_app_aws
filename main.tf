# Main Terraform Configuration - Foundation Infrastructure

check "health_check" {
  data "http" "health" {
    url = "https://${module.compute.alb_dns_name}/health"
    
    # Only check in production after deployment
    count = var.environment == "prod" && length(module.compute.alb_dns_name) > 0 ? 1 : 0
  }
  
  assert {
    condition     = length(data.http.health) == 0 || data.http.health[0].status_code == 200
    error_message = "Health check endpoint is not responding with 200 OK."
  }
}

check "backup_validation" {
  assert {
    condition     = module.database.db_instance_id != "" ? var.db_backup_retention_period >= 7 : true
    error_message = "Database backup retention must be at least 7 days for production."
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix           = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  
  enable_nat_gateway       = true
  single_nat_gateway       = !local.is_production && var.enable_cost_optimization
  enable_vpc_endpoints     = true
  enable_vpc_flow_logs     = var.enable_vpc_flow_logs
  flow_logs_retention_days = var.cloudwatch_retention_days
  enable_ipv6             = false
  
  aws_region = var.aws_region
  tags       = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  name_prefix         = local.name_prefix
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  allowed_cidr_blocks = var.allowed_cidr_blocks
  
  s3_bucket_arn              = module.storage.assets_bucket_arn
  db_secret_arn              = module.security.db_password_secret_arn
  db_username                = var.db_username
  enable_enhanced_monitoring = var.enable_enhanced_monitoring
  kms_deletion_window       = var.kms_key_deletion_window
  
  enable_waf       = local.is_production
  enable_guardduty = local.enable_guardduty
  
  tags = local.common_tags
}

# Storage Module - S3 Buckets
module "storage" {
  source = "./modules/storage"
  
  name_prefix = local.name_prefix
  bucket_name = local.s3_bucket_name
  kms_key_arn = module.security.kms_key_arn
  
  enable_versioning           = var.enable_s3_versioning
  enable_lifecycle            = true
  lifecycle_transition_days   = var.s3_lifecycle_days
  lifecycle_glacier_days      = var.s3_lifecycle_days * 2
  lifecycle_expiration_days   = var.s3_lifecycle_days * 8
  enable_intelligent_tiering  = var.enable_cost_optimization
  
  tags = local.common_tags
}

# Database Module - RDS PostgreSQL
module "database" {
  source = "./modules/database"
  
  name_prefix                = local.name_prefix
  database_subnet_ids        = module.vpc.database_subnet_ids
  database_security_group_id = module.security.database_security_group_id
  kms_key_arn               = module.security.kms_key_arn
  
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = local.is_production ? "io2" : "gp3"
  iops                  = local.is_production ? 3000 : null
  
  database_name   = "${var.project_name}db"
  master_username = var.db_username
  master_password = random_password.db_temp.result  # Will be rotated via Secrets Manager
  
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.enable_deletion_protection
  
  monitoring_role_arn                   = module.security.rds_monitoring_role_arn
  monitoring_interval                   = var.enable_enhanced_monitoring ? 60 : 0
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = local.is_production ? 731 : 7
  
  create_read_replica = local.is_production
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  tags = local.common_tags
}

# Compute Module - ALB and Auto Scaling Group
module "compute" {
  source = "./modules/compute"
  
  name_prefix        = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  
  alb_security_group_id = module.security.alb_security_group_id
  app_security_group_id = module.security.app_security_group_id
  instance_profile_name = module.security.ec2_instance_profile_name
  kms_key_arn          = module.security.kms_key_arn
  
  instance_type           = var.instance_type
  instance_types_override = ["${var.instance_type}", "t3a.medium", "t3.large"]
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  
  on_demand_base_capacity = local.is_production ? var.min_size : 1
  on_demand_percentage    = local.is_production ? 100 : 20
  spot_max_price         = var.spot_max_price
  
  health_check_path          = var.health_check_path
  certificate_arn           = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
  
  alb_logs_bucket = module.storage.alb_logs_bucket_id
  s3_bucket_name  = module.storage.assets_bucket_id
  db_secret_arn   = module.security.db_password_secret_arn
  
  environment    = var.environment
  aws_region     = var.aws_region
  waf_web_acl_arn = module.security.waf_web_acl_arn
  
  app_config_parameters = {
    "database_endpoint" = module.database.db_instance_endpoint
    "s3_bucket"        = module.storage.assets_bucket_id
    "environment"      = var.environment
  }
  
  tags = local.common_tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name              = "${local.name_prefix}-alerts"
  kms_master_key_id = module.security.kms_key_arn
  
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Temporary password for RDS (will be stored in Secrets Manager)
resource "random_password" "db_temp" {
  length  = 32
  special = true
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  name_prefix             = local.name_prefix
  aws_region              = var.aws_region
  alb_arn_suffix          = split("/", module.compute.alb_arn)[3]
  target_group_arn_suffix = split(":", module.compute.target_group_arn)[5]
  app_log_group           = module.compute.cloudwatch_log_group_name
  db_instance_id          = module.database.db_instance_id
  alarm_actions           = [aws_sns_topic.alerts.arn]
  sns_topic_arn           = aws_sns_topic.alerts.arn
  
  enable_synthetics      = local.is_production
  synthetics_bucket      = module.storage.logs_bucket_id
  enable_xray           = local.is_production
  enable_auto_recovery  = true
  enable_cost_monitoring = true
  
  tags = local.common_tags
}

# S3 Bucket for Terraform State (if needed)
resource "aws_s3_bucket" "terraform_state" {
  count  = var.environment == "dev" ? 1 : 0
  bucket = "${local.name_prefix}-terraform-state-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-terraform-state"
    }
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.environment == "dev" ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.environment == "dev" ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.security.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.environment == "dev" ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  count          = var.environment == "dev" ? 1 : 0
  name           = "${local.name_prefix}-terraform-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = module.security.kms_key_arn
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-terraform-lock"
    }
  )
}
