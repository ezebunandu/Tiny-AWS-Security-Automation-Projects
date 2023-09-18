provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

resource "aws_cloudtrail" "iam_config_change_monitor" {
  name                          = "iam_config_change_monitor"
  s3_bucket_name                = aws_s3_bucket.iam_config_change_monitor.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = true # this needs to be enabled to capture events from iam
}

resource "aws_s3_bucket" "iam_config_change_monitor" {
  bucket        = "iam-config-change-monitor-trail"
  force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.iam_config_change_monitor.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/iam_config_change_monitor"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.iam_config_change_monitor.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/iam_config_change_monitor"]
    }
  }
}
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.iam_config_change_monitor.id
  policy = data.aws_iam_policy_document.cloudtrail.json
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}
