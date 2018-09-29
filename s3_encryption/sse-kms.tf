resource "aws_kms_key" "sse_kms_example_key" {
    description = "SSE-KMS example key"
    deletion_window_in_days = 7
}

resource "aws_s3_bucket" "sse_kms" {
    bucket = "${var.sse_kms_bucket_name}"
    force_destroy = true
}

data "template_file" "sse_kms_bucket_policy" {
    template = "${file("sse-kms-bucket-policy.json")}"
    vars {
        bucket_name = "${var.sse_kms_bucket_name}"
    }
}

resource "aws_s3_bucket_policy" "sse_kms" {
    bucket = "${aws_s3_bucket.sse_kms.id}"
    policy = "${data.template_file.sse_kms_bucket_policy.rendered}"
}

output "sse_kms_example_key_id" {
    value = "${aws_kms_key.sse_kms_example_key.key_id}"
}
