import boto3
import logging
import gzip
import json
import base64
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)



# ---Main Handler---
def lambda_handler(event, context):
    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    payload = json.loads(uncompressed_payload)

    log_event = payload['logEvents']
    logger.debug(log_event)
    
    ts = log_event[0]['timestamp']
    logger.debug(ts)
    timestamp = datetime.utcfromtimestamp(ts/1000).strftime('%Y-%m-%d %H:%M:%S')
    
    bot_log = json.loads(log_event[0]['message'])
    
    userID = bot_log.get('userId')
    intent = bot_log['intent']
    sessionID = bot_log.get('sessionId')
    slots = bot_log['slots']
    
    # DynamoDB client for posting bot responses
    client = boto3.resource("dynamodb")
    table = client.Table("Processing")

    table.put_item(
        Item={
            'UserID#Intent': userID+'#'+intent,
            'SessionID': sessionID,
            'Slots': slots,
            'TimeStamp': timestamp
        }
    )
