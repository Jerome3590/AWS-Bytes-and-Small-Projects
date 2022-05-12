import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


# ---Main Handler---
def lambda_handler(event, context):
    logger.debug(event)
    try:
        if event['invocationSource'] == 'FulfillmentCodeHook':
            intent_name = event['currentIntent']['name']
            if intent_name == 'intake':
                return complete_survey(event)
            elif intent_name == 'test':
                return complete_survey(event)
        else:
            raise ValueError('Must be Fullfillment')

    except ValueError:
        logger.debug(event)

    else:
        logger.debug(event)


def complete_survey(event):
    logger.debug(event)
    userID = event.get('userId')
    logger.debug(userID)
    intent = event['currentIntent']['name']
    slots = event['currentIntent']['slots']
    message_content = 'Survey complete. Clinician will review responses and send gift card to number on file.'
    fullfillment_state = 'Fulfilled'


    # DynamoDB client for posting final survey response
    client = boto3.resource("dynamodb")
    table = client.Table("YSAT")

    table.put_item(
        Item={
            'IntentName': intent,
            'UserID': userID,
            'Slots': slots
        }
    )

    response = {
        'dialogAction': {
            'type': 'Close',
            'fulfillmentState': fullfillment_state,
            'message': {'contentType': 'PlainText', 'content': message_content}
        }
        
    }
    
    logger.debug(response)
    return response
