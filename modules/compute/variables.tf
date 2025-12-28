variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group ID"
  type        = string
}

variable "app_security_group_id" {
  description = "Application security group ID"
  type        = string
}

variable "instance_profile_name" {
  description = "EC2 instance profile name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "instance_types_override" {
  description = "List of instance types for mixed instances policy"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t3.large"]
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 10
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 3
}

variable "on_demand_base_capacity" {
  description = "Base on-demand capacity"
  type        = number
  default     = 1
}

variable "on_demand_percentage" {
  description = "Percentage of on-demand instances above base"
  type        = number
  default     = 50
}

variable "spot_max_price" {
  description = "Maximum price for spot instances"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable ALB access logs"
  type        = bool
  default     = true
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB logs"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "scale_up_cpu_threshold" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 70
}

variable "scale_down_cpu_threshold" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "s3_bucket_name" {
  description = "S3 bucket name for application"
  type        = string
}

variable "db_secret_arn" {
  description = "Database secret ARN"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
  default     = ""
}

variable "app_config_parameters" {
  description = "Application configuration parameters for SSM"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
