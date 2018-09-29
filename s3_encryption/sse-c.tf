resource "aws_s3_bucket" "sse_c" {
    bucket = "${var.sse_c_bucket_name}"
    force_destroy = true
}
