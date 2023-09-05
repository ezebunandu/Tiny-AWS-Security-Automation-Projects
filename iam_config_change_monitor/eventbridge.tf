resource "aws_cloudwatch_event_rule" "iam-config-change-monitor" {
  name        = "iam-config-changes-rule"
  description = "Monitor for IAM configuration changes"

  event_pattern = jsonencode({
    source = ["aws.iam"],
    detail-type = [
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : [
        "CreateAccessKey",
        "CreateLoginProfile",
        "UpdateAssumeRolePolicy"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.iam-config-change-monitor.name
  arn       = aws_lambda_function.iam_config_change_monitor.arn
  target_id = "iam-config-change-monitor"

}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role-for-function-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required policy to the Lambda role
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda_role_attachment"
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute" # Built-in AWS managed policy for Lambda execution
  roles      = [aws_iam_role.lambda_role.name]
}

resource "aws_lambda_function" "iam_config_change_monitor" {
  filename         = "lambda_function.zip"
  function_name    = "iam_config_change_notifier"
  role             = aws_iam_role.lambda_role.arn
  handler          = "iam_config_monitor.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_iam_policy" "publish-to-sns" {
  name = "lambda-publish-to-sns"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.iam-config-change-monitor.arn
      },
      {
        Effect = "Allow",
        Action = [
          "sns:CreateTopic"
        ],
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM policy for sns to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_sns_publish_attachment" {
  policy_arn = aws_iam_policy.publish-to-sns.arn
  role       = aws_iam_role.lambda_role.name
}

# Allows the cloudwatch event be able to trigger the Lambda function
resource "aws_lambda_permission" "event_rule_permission" {
  statement_id  = "AllowExecutionFromCloudWatchEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iam_config_change_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.iam-config-change-monitor.arn
}

resource "aws_sns_topic" "iam-config-change-monitor" {
  name         = "iam-config-change-monitor-topic"
  display_name = "Receive Alerts When an API call is made to change the IAM config of the account"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.iam-config-change-monitor.arn
  protocol  = "email"
  endpoint  = "samuel.ezebunandu@outlook.com" # change this to the email you want to subscribe to the topic
}
