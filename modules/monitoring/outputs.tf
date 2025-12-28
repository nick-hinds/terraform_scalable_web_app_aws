output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "canary_name" {
  description = "CloudWatch Synthetics Canary name"
  value       = try(aws_synthetics_canary.website_monitor[0].name, "")
}

output "cost_monitor_arn" {
  description = "Cost Anomaly Monitor ARN"
  value       = try(aws_ce_anomaly_monitor.main[0].arn, "")
}
