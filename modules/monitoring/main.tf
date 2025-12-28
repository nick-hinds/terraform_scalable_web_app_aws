# Monitoring Module - CloudWatch Dashboards, Alarms, and Observability

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Avg Response Time" }],
            [".", "RequestCount", { stat = "Sum", label = "Request Count" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum", label = "2XX Responses" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Errors" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "Application Load Balancer Metrics"
          period  = 300
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { "stat": "Average", "label": "Average CPU" }],
            [".", ".", { "stat": "Maximum", "label": "Max CPU" }],
            ["AWS/EC2", "NetworkIn", { "stat": "Sum", "label": "Network In" }],
            [".", "NetworkOut", { "stat": "Sum", "label": "Network Out" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { "stat": "Average", "label": "CPU Utilization" }],
            [".", "DatabaseConnections", { "stat": "Average", "label": "DB Connections" }],
            [".", "FreeableMemory", { "stat": "Average", "label": "Freeable Memory" }],
            [".", "ReadLatency", { "stat": "Average", "label": "Read Latency" }],
            [".", "WriteLatency", { "stat": "Average", "label": "Write Latency" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "RDS Database Metrics"
          period  = 300
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", { "stat": "Average", "label": "Bucket Size" }],
            [".", "NumberOfObjects", { "stat": "Average", "label": "Object Count" }],
            [".", "AllRequests", { "stat": "Sum", "label": "All Requests" }],
            [".", "4xxErrors", { "stat": "Sum", "label": "4XX Errors" }]
          ]
          view    = "timeSeries"
          region  = var.aws_region
          title   = "S3 Bucket Metrics"
          period  = 300
        }
      },
      {
        type = "log"
        properties = {
          query   = "SOURCE '${var.app_log_group}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Application Logs"
        }
      }
    ]
  })
}

# CloudWatch Log Insights Queries
resource "aws_cloudwatch_query_definition" "error_logs" {
  name = "${var.name_prefix}-error-logs"
  
  log_group_names = [
    var.app_log_group
  ]
  
  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/
    | sort @timestamp desc
    | limit 100
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_queries" {
  name = "${var.name_prefix}-slow-db-queries"
  
  log_group_names = [
    "/aws/rds/instance/${var.db_instance_id}/postgresql"
  ]
  
  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /duration:/
    | parse @message /duration: (?<duration>[0-9.]+)/
    | filter duration > 1000
    | sort duration desc
    | limit 50
  QUERY
}

# Additional CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Alert when there are unhealthy targets"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${var.name_prefix}-alb-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"
  alarm_description   = "Alert when response time is high"
  alarm_actions       = var.alarm_actions
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert on high 5XX errors"
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  
  tags = var.tags
}

# CloudWatch Synthetics Canary for Endpoint Monitoring
resource "aws_synthetics_canary" "website_monitor" {
  count                    = var.enable_synthetics ? 1 : 0
  name                     = "${var.name_prefix}-website-monitor"
  artifact_s3_location     = "s3://${var.synthetics_bucket}/canary-artifacts"
  execution_role_arn       = aws_iam_role.synthetics[0].arn
  handler                  = "apiCanaryBlueprint.handler"
  zip_file                 = "synthetic-canary.zip"
  runtime_version          = "syn-nodejs-puppeteer-7.0"
  
  schedule {
    expression = "rate(5 minutes)"
  }
  
  run_config {
    timeout_in_seconds = 60
    memory_in_mb      = 960
  }
  
  success_retention_period_in_days = 31
  failure_retention_period_in_days = 31
  
  tags = var.tags
}

# IAM Role for Synthetics
resource "aws_iam_role" "synthetics" {
  count = var.enable_synthetics ? 1 : 0
  name  = "${var.name_prefix}-synthetics-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy" "synthetics" {
  count = var.enable_synthetics ? 1 : 0
  name  = "${var.name_prefix}-synthetics-policy"
  role  = aws_iam_role.synthetics[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.synthetics_bucket}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# X-Ray Tracing Configuration
resource "aws_xray_sampling_rule" "main" {
  count        = var.enable_xray ? 1 : 0
  rule_name    = "${var.name_prefix}-sampling"
  priority     = 9000
  version      = 1
  reservoir_size = 1
  fixed_rate   = 0.05
  url_path     = "*"
  host         = "*"
  http_method  = "*"
  service_type = "*"
  service_name = "*"
  resource_arn = "*"
  
  tags = var.tags
}

# CloudWatch Logs Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.name_prefix}-error-count"
  log_group_name = var.app_log_group
  pattern        = "[ERROR]"
  
  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.name_prefix}/Application"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "request_duration" {
  name           = "${var.name_prefix}-request-duration"
  log_group_name = var.app_log_group
  pattern        = "[..., duration=*ms, ...]"
  
  metric_transformation {
    name      = "RequestDuration"
    namespace = "${var.name_prefix}/Application"
    value     = "$duration"
    unit      = "Milliseconds"
  }
}

# CloudWatch Events for Automated Responses
resource "aws_cloudwatch_event_rule" "auto_recovery" {
  count       = var.enable_auto_recovery ? 1 : 0
  name        = "${var.name_prefix}-auto-recovery"
  description = "Trigger auto-recovery actions"
  
  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["stopped", "terminated"]
    }
  })
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = var.enable_auto_recovery ? 1 : 0
  rule      = aws_cloudwatch_event_rule.auto_recovery[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# Cost Anomaly Detection
resource "aws_ce_anomaly_monitor" "main" {
  count             = var.enable_cost_monitoring ? 1 : 0
  name              = "${var.name_prefix}-cost-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
  
  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "main" {
  count     = var.enable_cost_monitoring ? 1 : 0
  name      = "${var.name_prefix}-cost-alerts"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_monitor.main[0].arn
  ]
  
  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
  }
  
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
      values        = ["20"]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }
  
  tags = var.tags
}
