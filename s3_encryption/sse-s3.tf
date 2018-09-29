resource "aws_s3_bucket" "sse_s3" {
    bucket = "${var.sse_s3_bucket_name}"
    acl = "public-read-write"
    force_destroy = true

    # Alternatively uncomment the below and comment the bucket policy
    #server_side_encryption_configuration {
    #    rule {
    #        apply_server_side_encryption_by_default {
    #            sse_algorithm = "AES256"
    #        }
    #    }
    #}
}

data "template_file" "sse_s3_bucket_policy" {
    template = "${file("sse-s3-bucket-policy.json")}"
    vars {
        bucket_name = "${var.sse_s3_bucket_name}"
    }
}

resource "aws_s3_bucket_policy" "sse_s3" {
    bucket = "${aws_s3_bucket.sse_s3.id}"
    policy = "${data.template_file.sse_s3_bucket_policy.rendered}"
}
