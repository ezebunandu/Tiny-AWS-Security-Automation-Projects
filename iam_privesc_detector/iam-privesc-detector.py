import boto3
import logging
import json

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


SNS_TOPIC_NAME = "iam-privesc-detector-monitor-topic"


def get_sns_topic_arn(name):
    # If you attempt to create an already existing topic
    # it will just return an object representing that topic
    # https://stackoverflow.com/questions/71088521/how-can-i-get-the-sns-topic-arn-using-the-topic-name-to-publish-a-sns-message-in
    sns_client = boto3.client("sns")
    topic = sns_client.create_topic(Name=name)
    return topic["TopicArn"]


def notify_admin(topic, event, account, username):
    sns_client = boto3.client("sns")
    response = sns_client.publish(
        TargetArn=topic,
        Subject="Potential IAM PrivEsc Event Detected",
        Message=f"""There has been a `{event}` event for user `{username}` in the `{account}` AWS account.
Please investigate immediately""",
    )

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        logger.info(f"SNS notification sent successfully - {response}")
    else:
        logger.error(f"Error sending SNS notification - {response}")

    return response


def lambda_handler(event, context):
    try:
        detail = event["detail"]
        account = event["account"]
        event_name = detail["eventName"]
        user_name = detail["requestParameters"]["userName"]

    except Exception as e:
        logger.error(f"{e}")
        raise e

    logger.info(f"{event_name} event detected.")
    topic = get_sns_topic_arn(SNS_TOPIC_NAME)
    notify_admin(topic=topic, event=event_name, account=account, username=user_name)
    logger.info("Notified the admin")

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda function executed successfully."),
    }
