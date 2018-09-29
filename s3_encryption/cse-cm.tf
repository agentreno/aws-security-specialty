resource "aws_s3_bucket" "cse_cm" {
    bucket = "${var.cse_cm_bucket_name}"
    force_destroy = true
}
