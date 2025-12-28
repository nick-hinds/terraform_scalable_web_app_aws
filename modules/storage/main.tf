# Storage Module - S3 for Static Assets and Logs

# S3 Bucket for Static Assets
resource "aws_s3_bucket" "assets" {
  bucket = var.bucket_name
  
  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
      Type = "Assets"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket CORS Configuration (for web applications)
resource "aws_s3_bucket_cors_configuration" "assets" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.assets.id
  
  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  
  rule {
    id     = "transition-old-objects"
    status = var.enable_lifecycle ? "Enabled" : "Disabled"
    
    transition {
      days          = var.lifecycle_transition_days
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = var.lifecycle_glacier_days
      storage_class = "GLACIER"
    }
    
    expiration {
      days = var.lifecycle_expiration_days
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  
  rule {
    id     = "delete-old-logs"
    status = "Enabled"
    
    filter {
      prefix = "logs/"
    }
    
    expiration {
      days = var.log_expiration_days
    }
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket_logging" "assets" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.assets.id
  
  target_bucket = aws_s3_bucket.logs[0].id
  target_prefix = "s3-access-logs/"
}

# S3 Bucket for Logs
resource "aws_s3_bucket" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${var.bucket_name}-logs"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_name}-logs"
      Type = "Logs"
    }
  )
}

# S3 Bucket ACL for Logs Bucket
resource "aws_s3_bucket_acl" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  
  access_control_policy {
    owner {
      id = data.aws_canonical_user_id.current.id
    }
    
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    
    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "WRITE"
    }
    
    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }
  }
}

# S3 Bucket Server-Side Encryption for Logs
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for Logs
resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for ALB Logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.bucket_name}-alb-logs"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.bucket_name}-alb-logs"
      Type = "ALB-Logs"
    }
  )
}

# S3 Bucket Policy for ALB Logs
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb/*"
      }
    ]
  })
}

# S3 Bucket Server-Side Encryption for ALB Logs
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for ALB Logs
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle for ALB Logs
resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  
  rule {
    id     = "delete-old-alb-logs"
    status = "Enabled"
    
    expiration {
      days = var.alb_log_expiration_days
    }
  }
}

# S3 Bucket Intelligent Tiering
resource "aws_s3_bucket_intelligent_tiering_configuration" "assets" {
  count  = var.enable_intelligent_tiering ? 1 : 0
  bucket = aws_s3_bucket.assets.id
  name   = "entire-bucket"
  
  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# S3 Bucket Metrics
resource "aws_s3_bucket_metric" "assets" {
  bucket = aws_s3_bucket.assets.id
  name   = "entire-bucket"
}

# S3 Bucket Inventory
resource "aws_s3_bucket_inventory" "assets" {
  count  = var.enable_inventory ? 1 : 0
  bucket = aws_s3_bucket.assets.id
  name   = "entire-bucket-weekly"
  
  included_object_versions = "All"
  
  schedule {
    frequency = "Weekly"
  }
  
  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.logs[0].arn
      prefix     = "inventory/"
      
      encryption {
        sse_s3 {
          # Use SSE-S3 for inventory
        }
      }
    }
  }
  
  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier"
  ]
}

# Data Sources
data "aws_canonical_user_id" "current" {}
data "aws_elb_service_account" "main" {}

# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.name_prefix}-s3-access"
  description = "Policy for accessing S3 buckets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.assets.arn,
          "${aws_s3_bucket.assets.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
  
  tags = var.tags
}
