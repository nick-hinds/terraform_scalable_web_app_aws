variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for assets"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle rules"
  type        = bool
  default     = true
}

variable "lifecycle_transition_days" {
  description = "Days before transitioning to STANDARD_IA"
  type        = number
  default     = 90
}

variable "lifecycle_glacier_days" {
  description = "Days before transitioning to GLACIER"
  type        = number
  default     = 180
}

variable "lifecycle_expiration_days" {
  description = "Days before expiration"
  type        = number
  default     = 730
}

variable "log_expiration_days" {
  description = "Days before log expiration"
  type        = number
  default     = 90
}

variable "alb_log_expiration_days" {
  description = "Days before ALB log expiration"
  type        = number
  default     = 30
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "enable_cors" {
  description = "Enable CORS configuration"
  type        = bool
  default     = false
}

variable "cors_allowed_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "PUT", "POST", "DELETE", "HEAD"]
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_expose_headers" {
  description = "CORS expose headers"
  type        = list(string)
  default     = ["ETag"]
}

variable "cors_max_age_seconds" {
  description = "CORS max age in seconds"
  type        = number
  default     = 3000
}

variable "enable_intelligent_tiering" {
  description = "Enable intelligent tiering"
  type        = bool
  default     = true
}

variable "enable_inventory" {
  description = "Enable S3 inventory"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
