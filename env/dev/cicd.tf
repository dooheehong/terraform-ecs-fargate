# create ci/cd user with access keys (for build system)
resource "aws_iam_user" "cicd" {
  name = "srv_${var.app}_${var.environment}_cicd"
}

resource "aws_iam_access_key" "cicd_keys" {
  user = aws_iam_user.cicd.name
}

# grant required permissions to deploy
data "aws_iam_policy_document" "cicd_policy" {
  # allows user to push/pull to the registry
  statement {
    sid = "ecr"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]

    resources = [
      aws_ecr_repository.devops-dev-backend.arn,
    ]
  }

  # allows user to deploy to ecs
  statement {
    sid = "ecs"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
    ]

    resources = [
      "*",
    ]
  }

  # allows user to run ecs task using task execution and app roles
  statement {
    sid = "approle"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.app_role.arn,
      aws_iam_role.ecsTaskExecutionRole.arn,
    ]
  }

  # allows users to put s3 objects
  statement {
    sid = "s3"

    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.devops-frontend.arn,
      "${aws_s3_bucket.devops-frontend.arn}/*",
      aws_s3_bucket.devops-overlay.arn,
      "${aws_s3_bucket.devops-overlay.arn}/*",
      aws_s3_bucket.devops-admin.arn,
      "${aws_s3_bucket.devops-admin.arn}/*",
      aws_s3_bucket.devops-assets.arn,
      "${aws_s3_bucket.devops-assets.arn}/*",
      aws_s3_bucket.devops-tts.arn,
      "${aws_s3_bucket.devops-tts.arn}/*",
    ]
  }

  # allows users to invalidate cloundfront cache
  statement {
    sid = "cloudfront"

    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]

    resources = [
      "*",
    ]
  }

  # allow users to pull secrets used for builds
  statement {
    sid = "secretmanager"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret.sm_secret_cicd.id
    ]
  }
}

resource "aws_iam_user_policy" "cicd_user_policy" {
  name   = "${var.app}_${var.environment}_cicd"
  user   = aws_iam_user.cicd.name
  policy = data.aws_iam_policy_document.cicd_policy.json
}

// data "aws_ecr_repository" "devops-dev-backend" {
//   name = var.app
// }

# The AWS keys for the CICD user to use in a build system
output "cicd_keys" {
  value = "terraform show -json | jq '.values.root_module.resources | .[] | select ( .address == \"aws_iam_access_key.cicd_keys\") | { AWS_ACCESS_KEY_ID: .values.id, AWS_SECRET_ACCESS_KEY: .values.secret }'"
}

# The URL for the docker image repo in ECR
output "docker_registry" {
  value = aws_ecr_repository.devops-dev-backend.repository_url
}
