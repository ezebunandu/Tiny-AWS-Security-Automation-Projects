# To-Do: Maybe can use a remote state file to avoid the mess below
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "monica"
  region                   = "us-east-1" # Replace with your desired region
}

# Create a CloudWatch Event Rule to monitor "CreateAccessKey" API events for the root user
resource "aws_cloudwatch_event_rule" "root_user_create_access_key_rule" {
  name        = "RootUserCreateAccessKeyRule"
  description = "Monitors 'CreateAccessKey' API events for the root user"

  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail" : {
      "eventSource" : ["iam.amazonaws.com"],
      "eventName" : ["CreateAccessKey"],
      "userIdentity" : {
        "type" : ["Root"]
      }
    }
  })
}

# Create an IAM Role for the Lambda function that the event rule will trigger
resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"

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

# Create the Lambda function
resource "aws_lambda_function" "root_user_access_key_creation_detector" {
  filename         = "lambda_function.zip" # Replace with the path to your Lambda function code
  function_name    = "RootUserAccessKeyCreationDetector"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"                  # Replace with the appropriate handler function name
  runtime          = "python3.8"                             # Replace with the desired runtime version
  source_code_hash = filebase64sha256("lambda_function.zip") # Replace with the path to your Lambda function code
}

# Create an SNS topic for notifications
resource "aws_sns_topic" "root_user_access_key_topic" {
  name         = "RootUserAccessKeyTopic"
  display_name = "Root User Access Key Usage Alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.root_user_access_key_topic.arn
  protocol  = "email"
  endpoint  = "samuel.ezebunandu@outlook.com" # change this to the email you want to subscribe to the topic
}

# iam policy to allow the lambda publish to the sns topic
resource "aws_iam_policy" "sns_publish_policy" {
  name = "SNSPublishPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.root_user_access_key_topic.arn
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
  policy_arn = aws_iam_policy.sns_publish_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Allows the cloudwatch event be able to trigger the Lambda function
resource "aws_lambda_permission" "event_rule_permission" {
  statement_id  = "AllowExecutionFromCloudWatchEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.root_user_access_key_creation_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.root_user_create_access_key_rule.arn
}

# Attach the Lambda function to the CloudWatch Event Rule as a target
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule      = aws_cloudwatch_event_rule.root_user_create_access_key_rule.name
  arn       = aws_lambda_function.root_user_access_key_creation_detector.arn
  target_id = "RootUserLambdaTarget"

}
