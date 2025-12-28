# Production Environment Configuration
# File: environments/prod/terraform.tfvars

# Basic Configuration
environment  = "prod"
project_name = "webapp"
aws_region   = "us-east-1"

# Availability Zones (3 AZs for high availability)
azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Network Configuration - Production network
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

# Compute Configuration - Production sizing
instance_type    = "t3.large"
min_size         = 3
max_size         = 20
desired_capacity = 5

# Database Configuration - Production grade
db_instance_class           = "db.r6g.xlarge"
db_engine_version          = "16.3"
db_allocated_storage       = 100
db_max_allocated_storage   = 1000
db_username                = "dbadmin"
db_multi_az                = true   # Required for production
db_backup_retention_period = 30     # 30 days of backups

# Security Configuration - Maximum security
allowed_cidr_blocks        = ["10.0.0.0/16"]  # VPC only
enable_deletion_protection = true              # Prevent accidental deletion
enable_vpc_flow_logs       = true             # Full monitoring
kms_key_deletion_window    = 30               # 30 day deletion window

# Monitoring Configuration - Comprehensive monitoring
enable_enhanced_monitoring  = true
enable_performance_insights = true
cloudwatch_retention_days   = 90  # 3 months

# Application Configuration
health_check_path = "/health"
certificate_arn   = "arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID"  # Your production certificate

# S3 Configuration
enable_s3_versioning = true
s3_lifecycle_days    = 90

# Cost Optimization - Reliability over cost
enable_cost_optimization = false  # No spot instances
enable_spot_instances    = false
spot_max_price          = ""

# CDN and WAF - Full protection
enable_cdn = true
enable_waf = true

# CDN Configuration
cdn_price_class     = "PriceClass_All"  # Global distribution
cdn_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT:certificate/CDN-CERT-ID"  # CloudFront certificate
domain_name         = "app.example.com"
route53_zone_id     = "Z1234567890ABC"

# Disaster Recovery
dr_region = "us-west-2"  # Disaster recovery region

# Alerting
alert_email = "prod-oncall@example.com"

# Tags
additional_tags = {
  Owner       = "Production Team"
  CostCenter  = "Operations"
  Environment = "Production"
  Compliance  = "PCI-DSS"
  DataClass   = "Confidential"
  Backup      = "Required"
  DR          = "Required"
}
