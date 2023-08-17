import boto3
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

sns_arn = os.environ["SNSTOPIC"]


def get_cloudtrail_status(trailname):
    client = boto3.client("cloudtrail")
    response = client.get_trail_status(Name=trailname)

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        response = response["IsLogging"]
        logger.info(f"Status of CloudTrail logging for {trailname} - {response}")
    else:
        logger.error(
            f"Error getting CloudTrail logging status for {trailname} - {response}"
        )

    return response


def enable_cloudtrail(trailname):
    client = boto3.client("cloudtrail")
    response = client.start_logging(Name=trailname)

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        logger.info(
            f"Response on enabling CloudTrail logging for {trailname} - {response}"
        )
    else:
        logger.error(f"Error enabling CloudTrail logging for {trailname} - {response}")

    return response


def notify_admin(topic, description):
    sns_client = boto3.client("sns")
    response = sns_client.publish(
        TargetArn=topic,
        Message=f'CloudTrail logging state change detected. Event description: "{description}"',
        Subject="CloudTrail Logging Alert",
    )

    if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        logger.info(f"SNS notification sent successfully - {response}")
    else:
        logger.error(f"Error sending SNS notification - {response}")

    return response


def handler(event, context):
    logger.setLevel(logging.INFO)
    logger.info("Starting automatic CloudTrail remediation response")

    trail_arn = event["detail"]["findings"][0]["ProductFields"][
        "action/awsApiCallAction/affectedResources/AWS::CloudTrail::Trail"
    ]
    description = event["detail"]["findings"][0]["Description"]
    region = event["detail"]["findings"][0]["Resources"][0]["Region"]

    try:
        response = enable_cloudtrail(trail_arn)
        status = get_cloudtrail_status(trail_arn)
        if response["ResponseMetadata"]["HTTPStatusCode"] == 200:
            message = (
                f"CloudTrail logging status for trail - {trail_arn}: {status}\n"
                f"{description}\n"
                f"Review additional information in Security Hub - "
                f"https://console.aws.amazon.com/securityhub/home?region={region}#/findings"
            )
            notify_admin(sns_arn, message)
            logger.info(
                f"Completed automatic CloudTrail remediation response for {trail_arn} - {response}"
            )
        else:
            logger.error(f"Something went wrong - {trail_arn}, {event}")
    except Exception as e:
        message = f"{e} \n \n {event}"
        logger.error(f"{e}, {event}")
        notify_admin(sns_arn, message)
