# Development Environment Configuration
# File: environments/dev/terraform.tfvars

# Basic Configuration
environment  = "dev"
project_name = "webapp"
aws_region   = "us-east-1"

# Availability Zones (2 AZs for dev to save costs)
azs = ["us-east-1a", "us-east-1b"]

# Network Configuration - Smaller subnets for dev
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]

# Compute Configuration - Minimal for dev
instance_type    = "t3.micro"
min_size         = 1
max_size         = 3
desired_capacity = 1

# Database Configuration - Smallest instance for dev
db_instance_class           = "db.t3.micro"
db_engine_version          = "16.3"
db_allocated_storage       = 20
db_max_allocated_storage   = 100
db_username                = "dbadmin"
db_multi_az                = false  # Single AZ for dev
db_backup_retention_period = 7      # Minimum backups

# Security Configuration - Relaxed for dev
allowed_cidr_blocks        = ["0.0.0.0/0"]  # Open for testing
enable_deletion_protection = false          # Allow easy cleanup
enable_vpc_flow_logs       = false          # Save costs
kms_key_deletion_window    = 7              # Quick deletion

# Monitoring Configuration - Basic monitoring
enable_enhanced_monitoring  = false
enable_performance_insights = false
cloudwatch_retention_days   = 7

# Application Configuration
health_check_path = "/health"
# certificate_arn = ""  # No HTTPS in dev

# S3 Configuration
enable_s3_versioning = false  # Save storage costs
s3_lifecycle_days    = 30      # Quick lifecycle

# Cost Optimization - Maximum savings
enable_cost_optimization = true
enable_spot_instances    = true
spot_max_price          = "0.01"  # Very low spot price

# CDN and WAF - Disabled for dev
enable_cdn = false
enable_waf = false

# Alerting
alert_email = "dev-team@example.com"

# Tags
additional_tags = {
  Owner       = "Development Team"
  CostCenter  = "Engineering"
  Environment = "Development"
  AutoShutdown = "true"  # For cost saving scripts
}
