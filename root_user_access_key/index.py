import boto3
import json
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


SNS_TOPIC_NAME = "RootUserAccessKeyTopic"


def get_sns_topic_arn(name):
    # If you attempt to create an already existing topic
    # it will just return an object representing that topic
    # https://stackoverflow.com/questions/71088521/how-can-i-get-the-sns-topic-arn-using-the-topic-name-to-publish-a-sns-message-in
    sns_client = boto3.client("sns")
    topic = sns_client.create_topic(Name=name)
    return topic["TopicArn"]


def disable_root_user_access_key(access_key_id, username):
    iam_client = boto3.client("iam")
    response = iam_client.update_access_key(
        AccessKeyId=access_key_id, UserName=username, Status="Inactive"
    )

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        logger.info(f"Access key successfully disabled - {response}")
    else:
        logger.error(f"Error disabling access key - {response}")
    return response


def notify_admin(topic):
    sns_client = boto3.client("sns")
    response = sns_client.publish(
        TargetArn=topic,
        Subject="Alert: Root User Access Key Creation Detected",
        Message="An access key was created for the root user. Please investigate immediately",
    )

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        logger.info(f"SNS notification sent successfully - {response}")
    else:
        logger.error(f"Error sending SNS notification - {response}")

    return response


def lambda_handler(event, context):  # sourcery skip: extract-method
    try:
        detail = event["detail"]

        if (
            detail["eventName"] == "CreateAccessKey"
            and detail["userIdentity"]["type"] == "Root"
        ):
            access_key_id = detail["responseElements"]["accessKey"]["accessKeyId"]
            logger.info("An access key was created for the root user")
            topic = get_sns_topic_arn(SNS_TOPIC_NAME)
            disable_root_user_access_key(access_key_id=access_key_id, username="Root")
            notify_admin(topic=topic)
            logger.info("Notified the admin")

    except Exception as e:
        logger.error(f"{e}")

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda function executed successfully."),
    }
