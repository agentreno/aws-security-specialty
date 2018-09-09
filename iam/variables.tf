# AWS Account ID for a production account
variable "prod-account-id" {}

# AWS Account ID for a development account
variable "dev-account-id" {}

# Region
variable "region" {
    default = "eu-west-1"
}

# Keybase User ID to use to encrypt the test users password
variable "keybase-id" {}
