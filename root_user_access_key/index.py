import boto3
import json

def lambda_handler(event, context):
    # Check if the event contains any API calls made by the root user
    for record in event['Records']:
        try:
            detail = json.loads(record['Sns']['Message'])['detail']
            user_identity = detail.get('userIdentity', {})
            
            if user_identity.get('type') == 'Root':
                print("Root user access key detected!")
                # You can add your desired actions here, such as sending notifications or logging the event.
                
        except Exception as e:
            print(f"Error processing event record: {e}")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Lambda function executed successfully.')
    }
