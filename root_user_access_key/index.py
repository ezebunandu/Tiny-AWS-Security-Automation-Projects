import boto3
import json


def lambda_handler(event, context):
    # Initialize the AWS SDK clients
    sns_client = boto3.client("sns")
    # Check if the event contains "CreateAccessKey" API event for the root user
    try:
        detail = event["detail"]

        if (
            detail["eventName"] == "CreateAccessKey"
            and detail["userIdentity"]["type"] == "Root"
        ):
            print("Access Key was created for the root user!")

            email_subject = (
                "Alert: Root User Access Key Creation Detected and Access Key Deleted"
            )
            email_body = "An access key was created for the root user. Please investigate immediately."

            # https://stackoverflow.com/questions/71088521/how-can-i-get-the-sns-topic-arn-using-the-topic-name-to-publish-a-sns-message-in
            topic = sns_client.create_topic(Name="RootUserAccessKeyTopic")
            topic_arn = topic["TopicArn"]
            sns_client.publish(
                TopicArn=topic_arn,
                Message=email_body,
                Subject=email_subject,
            )

    except Exception as e:
        print(f"Error processing event record: {e}")

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda function executed successfully."),
    }
