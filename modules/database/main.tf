# Database Module - RDS PostgreSQL with High Availability

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.database_subnet_ids
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-subnet-group"
    }
  )
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.name_prefix}-db-params"
  family = "postgres${split(".", var.engine_version)[0]}"
  
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements,pgaudit"
  }
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  parameter {
    name  = "log_duration"
    value = "1"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # Log queries taking more than 1 second
  }
  
  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-params"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.name_prefix}-db"
  
  # Engine Configuration
  engine                      = "postgres"
  engine_version             = var.engine_version
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  
  # Instance Configuration
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  iops                  = var.storage_type == "io1" || var.storage_type == "io2" ? var.iops : null
  storage_encrypted     = true
  kms_key_id           = var.kms_key_arn
  
  # Database Configuration
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port
  
  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  
  # High Availability
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : var.availability_zone
  
  # Backup Configuration
  backup_retention_period   = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  copy_tags_to_snapshot    = true
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  
  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval            = var.monitoring_interval
  monitoring_role_arn           = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
  performance_insights_enabled   = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_arn : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  
  # Parameter Group
  parameter_group_name = aws_db_parameter_group.main.name
  
  # Protection
  deletion_protection = var.deletion_protection
  
  # CA Certificate
  ca_cert_identifier = var.ca_cert_identifier
  
  # Timeouts
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db"
    }
  )
  
  lifecycle {
    ignore_changes = [password]
    
    # Terraform 1.14+ feature: postcondition
    postcondition {
      condition     = self.storage_encrypted
      error_message = "Database storage must be encrypted."
    }
    
    postcondition {
      condition     = self.backup_retention_period >= 7
      error_message = "Backup retention period must be at least 7 days."
    }
    
    postcondition {
      condition     = !self.publicly_accessible
      error_message = "Database must not be publicly accessible."
    }
  }
}

# Read Replica (Optional)
resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0
  
  identifier = "${var.name_prefix}-db-read-replica"
  
  replicate_source_db = aws_db_instance.main.identifier
  
  # Instance Configuration
  instance_class        = var.read_replica_instance_class != "" ? var.read_replica_instance_class : var.instance_class
  storage_encrypted     = true
  
  # Network Configuration
  publicly_accessible = false
  
  # High Availability for Read Replica
  multi_az = var.read_replica_multi_az
  
  # Monitoring
  monitoring_interval            = var.monitoring_interval
  monitoring_role_arn           = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
  performance_insights_enabled   = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.kms_key_arn : null
  
  # Protection
  deletion_protection = var.deletion_protection
  
  skip_final_snapshot = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-db-read-replica"
    }
  )
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.name_prefix}-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.name_prefix}-db-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.storage_threshold_bytes
  alarm_description   = "This metric monitors RDS free storage"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.name_prefix}-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.connections_threshold
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
  
  tags = var.tags
}