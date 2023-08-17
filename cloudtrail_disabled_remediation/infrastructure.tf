provider "aws" {
  region = "us-east-1" # Set your desired region here
}

resource "aws_sns_topic" "cloudtrail_start_logging_sns_topic" {
  name = "CloudTrailStartLoggingSNSTopic"
}

resource "aws_lambda_function" "cloudtrail_start_logging_lambda_cwe" {
  filename      = "cloudtrail_start_logging_lambda_cwe.zip"
  function_name = "CloudTrailStartLoggingLambdaCWE"
  role          = aws_iam_role.cloudtrail_start_logging_role.arn
  handler       = "cloudtrail_start_logging_lambda_cwe.handler"
  runtime       = "python3.8"
  environment {
    variables = {
      SNSTOPIC = aws_sns_topic.cloudtrail_start_logging_sns_topic.arn
    }
  }
}

resource "aws_lambda_function" "cloudtrail_start_logging_lambda_sh" {
  filename      = "cloudtrail_start_logging_lambda_sh.zip"
  function_name = "CloudTrailStartLoggingLambdaSH"
  role          = aws_iam_role.cloudtrail_start_logging_role.arn
  handler       = "cloudtrail_start_logging_lambda_sh.handler"
  runtime       = "python3.8"
  environment {
    variables = {
      SNSTOPIC = aws_sns_topic.cloudtrail_start_logging_sns_topic.arn
    }
  }
}

resource "aws_iam_role" "cloudtrail_start_logging_role" {
  name = "CloudTrailStartLoggingIAMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  inline_policy {
    name = "cloudtrail_start_logging_policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = ["cloudtrail:StartLogging", "cloudtrail:GetTrailStatus"],
          Effect   = "Allow",
          Resource = "*"
        },
        {
          Action   = "sns:Publish",
          Effect   = "Allow",
          Resource = aws_sns_topic.cloudtrail_start_logging_sns_topic.arn
        },
        {
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
          Effect   = "Allow",
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}

resource "aws_cloudwatch_event_rule" "cloudtrail_start_logging_event_rule_cwe" {
  name        = "CloudTrailStartLoggingEventRuleforCWE"
  description = "CloudTrail - start logging if trail stopped"

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"],
    detail_type = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["cloudtrail.amazonaws.com"],
      eventName = [
        "StopLogging",
        "DeleteTrail",
        "UpdateTrail",
        "RemoveTags",
        "AddTags",
        "PutEventSelectors"
      ]
    }
  })
}


resource "aws_cloudwatch_event_rule" "cloudtrail_start_logging_event_rule_sh" {
  name        = "CloudTrailStartLoggingEventRuleforSH"
  description = "CloudTrail - start logging if trail stopped"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"],
    detail_type = ["Security Hub Findings - Imported"],
    detail = {
      findings = {
        Types = ["TTPs/Defense Evasion/Stealth:IAMUser-CloudTrailLoggingDisabled"]
      }
    }
  })
}



resource "aws_cloudwatch_event_target" "cloudtrail_start_logging_target_cwe" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_start_logging_event_rule_cwe.name
  target_id = "CloudTrailLoggingRemediationCWE"
  arn       = aws_lambda_function.cloudtrail_start_logging_lambda_cwe.arn
}

resource "aws_cloudwatch_event_target" "cloudtrail_start_logging_target_sh" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_start_logging_event_rule_sh.name
  target_id = "CloudTrailLoggingRemediationSH"
  arn       = aws_lambda_function.cloudtrail_start_logging_lambda_sh.arn
}
