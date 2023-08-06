import boto3
import json

def lambda_handler(event, context):
    # Initialize the AWS SDK clients
    sns_client = boto3.client('sns')
    # Check if the event contains "CreateAccessKey" API event for the root user
    try:
        detail = event['detail']
        
        if detail['eventName'] == 'CreateAccessKey' and detail['userIdentity']['type'] == 'Root':
            print(f"Access Key was created for the root user!")
          

            email_subject = "Alert: Root User Access Key Creation Detected and Access Key Deleted"
            email_body = f"An access key was created for the root user. Please investigate immediately."
        
            # To-Do: Create tags in the Terraform resource for the sns topic 
            # and dynamically fetch the sns topic using tags here to avoid 
            # this dirty mess of a hard-coded sns topic
            sns_client.publish(TopicArn='arn:aws:sns:us-east-1:331806078927:RootUserAccessKeyTopic', Message=email_body, Subject=email_subject)
            
    except Exception as e:
        print(f"Error processing event record: {e}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda function executed successfully.')
    }
