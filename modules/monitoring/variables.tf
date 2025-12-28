variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix for CloudWatch"
  type        = string
}

variable "app_log_group" {
  description = "Application CloudWatch log group name"
  type        = string
}

variable "db_instance_id" {
  description = "RDS instance ID"
  type        = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify for alarms"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

variable "enable_synthetics" {
  description = "Enable CloudWatch Synthetics monitoring"
  type        = bool
  default     = false
}

variable "synthetics_bucket" {
  description = "S3 bucket for Synthetics artifacts"
  type        = string
  default     = ""
}

variable "enable_xray" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = false
}

variable "enable_auto_recovery" {
  description = "Enable auto-recovery event rules"
  type        = bool
  default     = true
}

variable "enable_cost_monitoring" {
  description = "Enable cost anomaly detection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
