
# creates an application role that the container/task runs as
resource "aws_iam_role" "app_role" {
  name               = "${var.app}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role_policy.json
}

# assigns the app policy
resource "aws_iam_role_policy" "app_policy" {
  name   = "${var.app}-${var.environment}"
  role   = aws_iam_role.app_role.id
  policy = data.aws_iam_policy_document.app_policy.json
}

# TODO: fill out custom policy
data "aws_iam_policy_document" "app_policy" {
  statement {
    actions = [
      "ecs:DescribeClusters",
    ]

    resources = [
      aws_ecs_cluster.app.arn,
    ]
  }

  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:List*",
      "secretsmanager:GetRandomPassword",
      "secretsmanager:GetSecretValue",
      "ssm:*",
      "kms:Decrypt",
    ]

    resources = [
      aws_secretsmanager_secret.sm_secret.id,
      "${aws_secretsmanager_secret.sm_secret.id}/*",
      "${aws_secretsmanager_secret.sm_secret.id}:*"
    ]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "sqs:List*",
      "sqs:Get*",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:DeleteMessage",
    ]

    resources = [
      aws_sqs_queue.devops-tts-queue.arn,
      aws_sqs_queue.devops-tts-dead-letter-queue.arn,
    ]
  }

  statement {
    actions = [
      "s3:HeadBucket",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.devops-assets.arn,
      "${aws_s3_bucket.devops-assets.arn}/*",
      aws_s3_bucket.devops-tts.arn,
      "${aws_s3_bucket.devops-tts.arn}/*",
    ]
  }
}

data "aws_caller_identity" "current" {
}

# allow role to be assumed by ecs and local saml users (for development)
data "aws_iam_policy_document" "app_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_user" "app" {
  name = "srv_${var.app}_${var.environment}_app"
}

resource "aws_iam_access_key" "app_keys" {
  user = aws_iam_user.app.name
}

resource "aws_iam_user_policy" "app_user_policy" {
  name = "${var.app}_${var.environment}_app"
  user = aws_iam_user.app.name
  policy = data.aws_iam_policy_document.app_policy.json
}

output "app_keys" {
  value = "terraform show -json | jq '.values.root_module.resources | .[] | select ( .address == \"aws_iam_access_key.app_keys\") | { AWS_ACCESS_KEY_ID: .values.id, AWS_SECRET_ACCESS_KEY: .values.secret }'"
}
