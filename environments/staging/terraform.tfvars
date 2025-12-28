# Staging Environment Configuration
# File: environments/staging/terraform.tfvars

# Basic Configuration
environment  = "staging"
project_name = "webapp"
aws_region   = "us-east-1"

# Availability Zones (3 AZs for staging - production-like)
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Network Configuration - Full network like production
vpc_cidr              = "10.1.0.0/16"  # Different from prod
public_subnet_cidrs   = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs  = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
database_subnet_cidrs = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]

# Compute Configuration - Medium sizing
instance_type    = "t3.small"
min_size         = 2
max_size         = 6
desired_capacity = 2

# Database Configuration - Medium instance
db_instance_class           = "db.t3.small"
db_engine_version          = "16.3"
db_allocated_storage       = 50
db_max_allocated_storage   = 200
db_username                = "dbadmin"
db_multi_az                = true   # Multi-AZ like production
db_backup_retention_period = 14     # Two weeks of backups

# Security Configuration - Production-like
allowed_cidr_blocks        = ["10.0.0.0/8"]  # Internal only
enable_deletion_protection = false            # Still allow cleanup
enable_vpc_flow_logs       = true            # Enable monitoring
kms_key_deletion_window    = 14              # Moderate deletion window

# Monitoring Configuration - Full monitoring
enable_enhanced_monitoring  = true
enable_performance_insights = true
cloudwatch_retention_days   = 14

# Application Configuration
health_check_path = "/health"
certificate_arn   = ""  # Add your staging certificate ARN

# S3 Configuration
enable_s3_versioning = true
s3_lifecycle_days    = 60

# Cost Optimization - Balanced
enable_cost_optimization = true
enable_spot_instances    = true
spot_max_price          = "0.03"

# CDN and WAF - Test production features
enable_cdn = true
enable_waf = false  # Optional for staging

# Alerting
alert_email = "staging-alerts@example.com"

# Tags
additional_tags = {
  Owner       = "QA Team"
  CostCenter  = "Engineering"
  Environment = "Staging"
  Purpose     = "Pre-production Testing"
}
