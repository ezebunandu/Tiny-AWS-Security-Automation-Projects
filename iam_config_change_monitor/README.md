# IAM Persistence Detector

This automation will detect whenever a subset of potential privilege escalation actions are performed on an IAM identity in an AWS account.

These subset of actions have been chosen based on [Gerben Kleijn's 2019 Article on AWS IAM Privilege Escalation](https://bishopfox.com/blog/5-privesc-attack-vectors-in-aws)

The intent is to be able to detect when these actions are taken, as this could be potentially indicative of an attempt by an attack to escalate from a low-privilege user by exploiting IAM Permissions on Other Users.

## Installation

Ensure Terraform is installed and you have configured an IAM identity for the AWS CLI that Terraform will use for deployment

1. Clone the project repo
2. cd into the repo and configure the CLI with credentials for an admin user in your playground AWS account
3. Modify line 4 of `eventbridge.tf]` file to the email adddress you want to subscribe to the detection alerts and then run the following commands.
4. Run the following commands to deploy the detection infrastructure to your AWS account

```bash
$terraform init

$terraform plan

$terraform apply
```

## Smoke Testing

Login to the AWS Account, confirm that the following resources have been created:

* Cloudtrail trail that captures IAM events and writes to S3
* Eventbridge rule that tracks IAM config changes
* SNS topic that is the target of the Eventbridge rule
* From the IAM console, create an AWS user. You should get an alert.
