provider "aws" {
    profile = "development"
    region = "${var.region}"
}

# Cloudtrail setup
resource "aws_cloudtrail" "main" {
    name = "monitoring-example"
    s3_bucket_name = "${aws_s3_bucket.event_store.bucket}"
    is_multi_region_trail = true
    enable_log_file_validation = true

    # Cloudwatch log feed
    cloud_watch_logs_role_arn = "${aws_iam_role.cloudtrail_logging_role.arn}"
    cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.event_logs.arn}"
}

resource "aws_iam_role" "cloudtrail_logging_role" {
    name = "cloudtrail_logging_role"
    description = "Gives Cloudtrail access to Cloudwatch to send logs"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Effect": "Allow"
        }
    ]
}
EOF
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "cloudtrail_logging_policy" {
    name = "cloudtrail_logging_policy"
    description = "Gives Cloudtrail access to Cloudwatch to send logs"

    policy = "${data.aws_iam_policy_document.cloudtrail_logging_policy.json}"
}

data "aws_iam_policy_document" "cloudtrail_logging_policy" {
    statement {
        effect  = "Allow"
        actions = ["logs:CreateLogStream"]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.event_logs.name}:log-stream:*",
        ]
    }

    statement {
        effect  = "Allow"
        actions = ["logs:PutLogEvents"]

        resources = [
            "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.event_logs.name}:log-stream:*",
        ]
    }
}

data "template_file" "cloudtrail_s3_bucket_policy" {
    template = "${file("cloudtrail_s3_bucket_policy.json")}"
    vars {
        bucket_name = "${var.cloudtrail_bucket_name}"
    }
}

resource "aws_s3_bucket" "event_store" {
    bucket = "${var.cloudtrail_bucket_name}"
    force_destroy = true

    policy = "${data.template_file.cloudtrail_s3_bucket_policy.rendered}"
}

# Cloudwatch log setup
resource "aws_cloudwatch_log_group" "event_logs" {
    name = "${var.cloudwatch_log_group_name}"
}

# Cloudwatch filter, metric and alarm
resource "aws_cloudwatch_log_metric_filter" "deleted_lambda" {
    name = "DeletedLambdaFunction"
    pattern = "{ ($.eventSource = lambda.amazonaws.com) && ($.eventName = DeleteFunction*) }"
    log_group_name = "${aws_cloudwatch_log_group.event_logs.name}"

    metric_transformation {
        name = "${var.lambda_deletion_metric_name}"
        namespace = "${var.lambda_deletion_metric_namespace}"
        value = "1"
    }
}

resource "aws_cloudwatch_metric_alarm" "deleted_lambda" {
    alarm_name = "DeletedLambdaFunction"
    alarm_description = "Alerts for any Lambda function deletion"

    # Link to existing filter and metric
    metric_name = "${var.lambda_deletion_metric_name}"
    namespace = "${var.lambda_deletion_metric_namespace}"

    # Alarm for any deletion
    comparison_operator = "GreaterThanThreshold"
    threshold = 0
    statistic = "Sum"

    # Check once a minute
    evaluation_periods = "1"
    period = "60"

    # Notify SNS topic when entering ALARM
    alarm_actions = ["${aws_sns_topic.alerting.arn}"]
}

# SNS topic for alerting
resource "aws_sns_topic" "alerting" {
    name = "${var.sns_topic_name}"
}
