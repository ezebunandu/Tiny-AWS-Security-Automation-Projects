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
        { "prefix" : "Put" },
        { "prefix" : "Attach" },
        { "prefix" : "Detach" },
        { "prefix" : "Create" },
        { "prefix" : "Update" },
        { "prefix" : "Upload" },
        { "prefix" : "Delete" },
        { "prefix" : "Remove" },
        { "prefix" : "Set" }
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.iam-config-change-monitor.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.iam-config-change-monitor.arn
}

resource "aws_sns_topic" "iam-config-change-monitor" {
  name = "iam-config-change-monitor-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.iam-config-change-monitor.arn
  protocol  = "email"
  endpoint  = "samuel.ezebunandu@outlook.com" # change this to the email you want to subscribe to the topic
}

resource "aws_sns_topic_policy" "cloudwatch-event" {
  arn    = aws_sns_topic.iam-config-change-monitor.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.iam-config-change-monitor.arn]
  }
}


