# IAM Config Change Monitor

An automation project to monitor when changes are made to an AWS account's IAM configuration

## Installation

Ensure Terraform is installed and you have configured an IAM identity for the AWS CLI that Terraform will use for deployment

```hcl
terraform plan

terraform apply
```

## Smoke Testing

Login to the AWS Account, confirm that the following resources have been created:

* Cloudtrail trail that captures IAM events and writes to S3
* Eventbridge rule that tracks IAM config changes
* SNS topic that is the target of the Eventbridge rule
