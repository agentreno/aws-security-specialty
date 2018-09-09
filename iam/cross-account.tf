# Providers
provider "aws" {
    profile = "production"
    alias = "production"
    region = "${var.region}"
    allowed_account_ids = ["${var.prod-account-id}"]
}

provider "aws" {
    profile = "development"
    alias = "development"
    region = "${var.region}"
    allowed_account_ids = ["${var.dev-account-id}"]
}

# Policies
data "aws_iam_policy" "dev-administrator" {
    provider = "aws.production"
    arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy" "prod-administrator" {
    provider = "aws.production"
    arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# User
resource "aws_iam_user" "example" {
    provider = "aws.development"
    name = "CrossAccountExampleUser"
}

resource "aws_iam_user_policy_attachment" "example-dev-administrator" {
    provider = "aws.development"
    user = "${aws_iam_user.example.name}"
    policy_arn = "${data.aws_iam_policy.dev-administrator.arn}"
}

resource "aws_iam_user_login_profile" "example" {
    provider = "aws.development"
    user = "${aws_iam_user.example.name}"
    pgp_key = "${var.keybase-id}"
}

# Roles
data "aws_iam_policy_document" "assume-admin-role" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "AWS"
            identifiers = ["${aws_iam_user.example.arn}"]
        }
        condition {
            test = "DateLessThan"
            variable = "aws:CurrentTime"
            values = ["${timeadd(timestamp(), "5m")}"]
        }
    }
}

resource "aws_iam_role" "prod-administrator" {
    provider = "aws.production"
    name = "CrossAccountExampleRole"
    assume_role_policy = "${data.aws_iam_policy_document.assume-admin-role.json}"
}

resource "aws_iam_role_policy_attachment" "prod-administrator" {
    provider = "aws.production"
    role = "${aws_iam_role.prod-administrator.name}"
    policy_arn = "${data.aws_iam_policy.prod-administrator.arn}"
}

# Outputs
output "username" {
    value = "${aws_iam_user.example.name}"
}

output "password" {
    # Read with: terraform output password | base64 --decode | keybase pgp decrypt | xclip
    value = "${aws_iam_user_login_profile.example.encrypted_password}"
}
