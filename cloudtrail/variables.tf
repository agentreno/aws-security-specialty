variable "region" {
    default = "eu-west-1"
}

# S3 Bucket name to store Cloudtrail events
variable "cloudtrail_bucket_name" {
    default = "karl-monitoring-example"
}

# Cloudwatch log group name to receive Cloudtrail events
variable "cloudwatch_log_group_name" {
    default = "karl-monitoring-example"
}

# Example lambda deletion metric name
variable "lambda_deletion_metric_name" {
    default = "DeletedLambdaFunctionCount"
}

# Example lambda deletion metric namespace
variable "lambda_deletion_metric_namespace" {
    default = "MonitoringExample"
}

# Name for an SNS topic to use for alerting
variable "sns_topic_name" {
    default = "karl-monitoring-example"
}
