import boto3
import logging
import json

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


SNS_TOPIC_NAME = "iam-config-change-monitor-topic"


def get_sns_topic_arn(name):
    # If you attempt to create an already existing topic
    # it will just return an object representing that topic
    # https://stackoverflow.com/questions/71088521/how-can-i-get-the-sns-topic-arn-using-the-topic-name-to-publish-a-sns-message-in
    sns_client = boto3.client("sns")
    topic = sns_client.create_topic(Name=name)
    return topic["TopicArn"]


def notify_admin(topic, event, account):
    sns_client = boto3.client("sns")
    response = sns_client.publish(
        TargetArn=topic,
        Subject="Alert: IAM Configuration Change Detected",
        Message=f"""There has been a {event} change in the IAM configuration in the {account} AWS account.
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
        event = detail["eventName"]

    except Exception as e:
        logger.error(f"{e}")
        raise e

    logger.info(f"{event} event detected.")
    topic = get_sns_topic_arn(SNS_TOPIC_NAME)
    notify_admin(topic=topic, event=event, account=account)
    logger.info("Notified the admin")

    return {
        "statusCode": 200,
        "body": json.dumps("Lambda function executed successfully."),
    }
