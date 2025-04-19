# CloudWatch Log Group for NGINX access logs
resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/ec2/nginx/access.log"
  retention_in_days = 30

  tags = {
    Name        = "${var.project}-${var.environment}-nginx-logs"
    Environment = var.environment
  }
}

# CloudWatch RAM Utilization Metric Alarm
resource "aws_cloudwatch_metric_alarm" "ram_utilization" {
  count               = length(var.ec2_instances)
  alarm_name          = "${var.project}-${var.environment}-ram-utilization-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 RAM utilization"
  alarm_actions      = []

  dimensions = {
    InstanceId = var.ec2_instances[count.index].id
  }

  tags = {
    Name        = "${var.project}-${var.environment}-ram-alarm-${count.index + 1}"
    Environment = var.environment
  }
} 