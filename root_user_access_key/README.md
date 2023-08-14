### Root User Access Key Creation Detection

AWS Account Management best practice recommend not to use the root user in an AWS account for day-to-day administration. AWS explicitly states for you not to create access keys to grant programmatic access to the root user. This is sensible advice, if you consider that the root user has pretty much unrestricted powers within an AWS account (<https://docs.aws.amazon.com/accounts/latest/reference/best-practices-root-user.html>). If programmatic access is granted to the root user, an attacker who manages to compromise such credentials will have unrestricted access to all resources within the AWS account.

The idea here is to design a system that will detect when access keys are created for the root user and notify a security team to investigate. The current design uses AWS EventBridge, Lambda, and SNS. An EventBridge rule will detect API calls to create access keys for the root user and trigger a Lambda function. This Lambda function will push an email to an SNS topic that a security team subscribes to be alerted for such an event.

To extend this, we can configure the lambda function to also deactivate the newly created access key.

![Alt text](image-1.png)

If an AWS account has been set up according to the recommendations set up in the security pillar of the AWS well architected framework, then the root user account should be properly locked down and the probability that an access key can be created for the root user should be very low. An argument can be made whether there is any point to building detections for such extremely low probability events?  Because the compromise of the root user can have catastrophic consequences, I submit that this is a very good detection to alert on.

### How to Deploy

1. clone the repo to a local workspace
2. modify lines 3 & 4 in `infra.tf` to point to the location of credentials terraform will use to deploy the automation to your AWS account
3. assuming you already have terraform installed on your machine and the right aws credentials, then run `terraform plan` to see a plan of the infrastructure that will be provisioned
4. run `terraform apply` to provision the automation in your account.
5. inspect in the AWS console that you now have an Eventbridge rule that targets a Lambda function that pushes to an sns topic
6. smoke test the automation by creating an access key for the root user in your account
