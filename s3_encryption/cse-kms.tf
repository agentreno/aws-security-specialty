resource "aws_kms_key" "cse_kms_example_key" {
    description = "CSE-KMS example key"
    deletion_window_in_days = 7
}

resource "aws_s3_bucket" "cse_kms" {
    bucket = "${var.cse_kms_bucket_name}"
    force_destroy = true
}

output "cse_kms_example_key_id" {
    value = "${aws_kms_key.cse_kms_example_key.key_id}"
}
