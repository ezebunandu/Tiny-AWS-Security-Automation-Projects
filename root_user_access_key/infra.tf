# Define provider block to specify AWS as the provider
provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "hezebonica"
  region                   = "us-east-1" # Replace with your desired region
}

# Create a CloudWatch Event Rule to monitor API activity
resource "aws_cloudwatch_event_rule" "cloudtrail_event_rule" {
  name        = "RootUserAPICallsEventRule"
  description = "Monitors API calls made by root user"

  event_pattern = <<PATTERN
{
  "source": ["aws.ec2", "aws.s3", "aws.lambda"], 
  "detail": {
    "userIdentity": {
      "type": ["Root"]
    }
  }
}
PATTERN
}

# Create an IAM Role for the Lambda function
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
resource "aws_lambda_function" "root_user_access_key_detector" {
  filename         = "lambda.zip" # Replace with the path to your Lambda function code
  function_name    = "RootUserAccessKeyDetector"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"                # Replace with the appropriate handler function name
  runtime          = "python3.8"                    # Replace with the desired runtime version
  source_code_hash = filebase64sha256("lambda.zip") # Replace with the path to your Lambda function code

  # Set environment variables if needed
  environment {
    variables = {
      # Add any environment variables here if required by your Lambda function
    }
  }
}

# Attach the Lambda function to the CloudWatch Event Rule
resource "aws_cloudwatch_event_target" "lambda_event_target" {
  rule = aws_cloudwatch_event_rule.cloudtrail_event_rule.name
  arn  = aws_lambda_function.root_user_access_key_detector.arn
}
