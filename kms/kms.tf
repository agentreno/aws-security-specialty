data "aws_caller_identity" "current" {}

provider "aws" {
    profile = "development"
    region = "${var.region}"
}

# Create the key and bring it under IAM control
data "aws_iam_policy_document" "iam_control" {
    statement {
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        actions = ["kms:*"]
        resources = ["*"]
    }
}

resource "aws_kms_key" "test_key" {
    description = "Testing Key"
    deletion_window_in_days = 10

    # Add the key policy statement that enables IAM policy control
    policy = "${data.aws_iam_policy_document.iam_control.json}"
}

# Create a key administrator policy and role that can be assumed by this user
data "aws_iam_policy_document" "keyadmin_assume_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "AWS"
            identifiers = ["${data.aws_caller_identity.current.user_id}"]
        }
    }
}

data "aws_iam_policy_document" "keyadmin_policy" {
    statement {
        # Doesn't provide operations like encrypt, decrypt, generatedatakey etc.
        # Just administers keys
        actions = [
            "kms:Create*",
            "kms:Describe*",
            "kms:Enable*",
            "kms:List*",
            "kms:Put*",
            "kms:Update*",
            "kms:Revoke*",
            "kms:Disable*",
            "kms:Get*",
            "kms:Delete*",
            "kms:TagResource",
            "kms:UntagResource",
            "kms:ScheduleKeyDeletion",
            "kms:CancelKeyDeletion"
        ]

        resources = ["${aws_kms_key.test_key.arn}"]
    }
}

resource "aws_iam_role_policy" "keyadmin_policy" {
    name = "keyadmin_policy"
    role = "${aws_iam_role.keyadmin.id}"
    policy = "${data.aws_iam_policy_document.keyadmin_policy.json}"
}

resource "aws_iam_role" "keyadmin" {
    name = "test_keyadmin_role"
    assume_role_policy = "${data.aws_iam_policy_document.keyadmin_assume_policy.json}"
}

# Create a key user policy and role that can be assumed by this user
data "aws_iam_policy_document" "keyuser_assume_policy" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "AWS"
            identifiers = ["${data.aws_caller_identity.current.user_id}"]
        }
    }
}

data "aws_iam_policy_document" "keyuser_policy" {
    statement {
        actions = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey",
        ]

        resources = ["${aws_kms_key.test_key.arn}"]
    }
}

resource "aws_iam_role_policy" "keyuser_policy" {
    name = "keyuser_policy"
    role = "${aws_iam_role.keyuser.id}"
    policy = "${data.aws_iam_policy_document.keyuser_policy.json}"
}

resource "aws_iam_role" "keyuser" {
    name = "test_keyuser_role"
    assume_role_policy = "${data.aws_iam_policy_document.keyuser_assume_policy.json}"
}


# Outputs to put role arns in ~/.aws/config file
output "keyadmin_role_arn" {
    value = "${aws_iam_role.keyadmin.arn}"
}

output "keyuser_role_arn" {
    value = "${aws_iam_role.keyuser.arn}"
}

output "key_id" {
    value = "${aws_kms_key.test_key.key_id}"
}
