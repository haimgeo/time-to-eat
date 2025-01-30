import json
import boto3
import logging
import os
from datetime import datetime
from dateutil import tz

# Vars
dynamo_index = "cuisine-style-index"
local_tz = "Asia/Jerusalem"

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamo_db = boto3.client('dynamodb')

# Write requeste/response to dynamodb
def store_log(request_data, response_data, timestamp):
    item = {
        'timestamp': {'S': timestamp},
        'request': {'S': json.dumps(request_data)},
        'response': {'S': json.dumps(response_data)}
    }
    
    dynamo_db.put_item(
        TableName=os.environ["log_table_name"],
        Item=item
    )
    logger.info(f"Logged request and response to DynamoDB table {os.environ['log_table_name']}")

# Convert dynamodb response data to json
def dynamodb_to_json(dynamo_item):
    json_item = {}
    for key, value in dynamo_item.items():
        if 'S' in value:
            json_item[key] = value['S']
        elif 'N' in value:
            json_item[key] = int(value['N'])  # Convert number to integer
        elif 'BOOL' in value:
            json_item[key] = value['BOOL']
        elif 'L' in value:
            json_item[key] = [dynamodb_to_json(item) if isinstance(item, dict) else item for item in value['L']]
        elif 'M' in value:
            json_item[key] = dynamodb_to_json(value['M'])
    return json_item

def lambda_handler(event, context):
    try:
        # Parse the incoming event (parameters from the frontend)
        body = json.loads(event['body'])
        cuisine_style = body['cuisine_style']
        vegetarian = eval(body['vegetarian'])
        gluten_free = eval(body['gluten_free'])
        timestamp = body['timestamp']
        
        # Create Date object timezone aware
        utc_timezone = tz.gettz('UTC')
        local_timezone = tz.gettz(local_tz)
        timestamp_object = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%fZ')
        ts_object_utc = timestamp_object.replace(tzinfo=utc_timezone)
        ts_object_local = ts_object_utc.astimezone(local_timezone)
        request_hour = ts_object_local.hour

        # Query the DynamoDB data table based on the parameters: cuisine_style, vegetarian, gluten_free and openning hours
        response_dynamodb = dynamo_db.query(
            TableName=os.environ["data_table_name"],
            IndexName=dynamo_index,
            KeyConditionExpression='cuisine_style = :cuisine_style',
            ExpressionAttributeValues={
                ':cuisine_style': {'S': cuisine_style},
                ':request_hour': {'N': str(request_hour)},
                ':vegetarian': {'BOOL': vegetarian},
                ':gluten_free': {'BOOL': gluten_free}
            },
            FilterExpression='open_hour < :request_hour AND close_hour > :request_hour AND vegetarian = :vegetarian AND gluten_free = :gluten_free'
        )

        # Extract the items returned by the query
        items = [dynamodb_to_json(item) for item in response_dynamodb.get('Items', [])]

        # Extract relevant data from the event(request)
        http_method = event.get('requestContext', {}).get('http' ,{}).get('method' ,{})
        headers = event.get('headers', {})
        query_params = event.get('queryStringParameters', {})
        body = event.get('body', {})

        # Genrate the request for request history
        request = {
            "message": "Request received successfully",
            "method": http_method,
            "headers": headers,
            "queryParams": query_params,
            "body": json.loads(body) if body else None
        }

        # Create a response
        response = {
            'statusCode': 200,
            'body': json.dumps(items),
            'headers': {
                'Content-Type': 'application/json'
            }
        }

        # Log the outgoing response
        logger.info("Outgoing response: %s", json.dumps(response, indent=2))

        # Store the request and response in DynamoDB
        store_log(request, response, timestamp)

        # Return the results back to the frontend
        return response

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
