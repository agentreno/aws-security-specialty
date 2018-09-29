variable "region" {
    default = "eu-west-1"
}

variable "sse_s3_bucket_name" {
	default = "karl-sse-s3-example"
}

variable "sse_kms_bucket_name" {
	default = "karl-sse-kms-example"
}

variable "sse_c_bucket_name" {
	default = "karl-sse-c-example"
}

variable "cse_kms_bucket_name" {
	default = "karl-cse-kms-example"
}

variable "cse_cm_bucket_name" {
	default = "karl-cse-cm-example"
}
