import boto3
import logging
from boto3.dynamodb.conditions import Key

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# ---Helpers---
def remove_empty_from_dict(d):
    if type(d) is dict:
        return dict((k, remove_empty_from_dict(v)) for k, v in d.items() if v and remove_empty_from_dict(v))
    elif type(d) is list:
        return [remove_empty_from_dict(v) for v in d if v and remove_empty_from_dict(v)]
    else:
        return d

# ---Main Handler---
def lambda_handler(event, context):
    logger.debug(event)
    try:
        if event['invocationSource'] == 'DialogCodeHook':
            intent_name = event['currentIntent']['name']
            if intent_name != 'exit':
                return validate_input(event)
            elif intent_name == 'exit':
                return exit_survey(event)
        else:
            raise ValueError('Must be Fullfillment or Exit')
    except ValueError:
        return exit_survey(event)
    else:
        logger.debug(event)

def input_response(slots_updated):
    response = {
        'dialogAction': {
            'type': "Delegate",
            'slots': slots_updated
        }
    }
    return response
	
def get_saved_slots(userID,intent):
    userID_intent = userID+'#'+intent
    #DynamoDB session data
    client = boto3.resource("dynamodb")
    table = client.Table("Processing")
    resp = table.query(
        KeyConditionExpression=Key('UserID#Intent').eq(userID_intent),
        ScanIndexForward=False,
        Limit=1,
        ConsistentRead=True
    )
    return resp['Items'][0]['Slots']
    
def get_last_intent(userID):
    #DynamoDB session data
    client = boto3.resource("dynamodb")
    table = client.Table("Processing")
    try:
        userID_intent = userID + '#intake'
        response = table.query(
            KeyConditionExpression=Key('UserID#Intent').eq(userID_intent))
        last_intent = "intake"
    except ValueError:
        userID_intent = userID + '#discharge'
        response = table.query(
            KeyConditionExpression=Key('UserID#Intent').eq(userID_intent))
        last_intent = "discharge"
    except ValueError:
        userID_intent = userID + '#follow_up'
        response = table.query(
            KeyConditionExpression=Key('UserID#Intent').eq(userID_intent))
        last_intent = "follow_up"
    except ValueError:
        userID_intent = userID + '#test'
        response = table.query(
            KeyConditionExpression=Key('UserID#Intent').eq(userID_intent))
        last_intent = "test"
    else:
        pass
    return last_intent

def check_session(event):
    userID = event.get('userId')
    intent = event['currentIntent']['name']
    current_slots = event['currentIntent']['slots']
    logger.debug(current_slots)
    emptied_current = remove_empty_from_dict(current_slots)
    logger.debug(emptied_current)
    try:
        #DynamoDB session data
        saved_slots = get_saved_slots(userID,intent)
    except IndexError:
        logger.debug(f'No slots found. Using {current_slots}')
        return current_slots
    logger.debug(saved_slots)
    emptied_saved = remove_empty_from_dict(saved_slots)
    logger.debug(emptied_saved)
    if len(emptied_saved) > len(emptied_current):
        emptied_current.update(emptied_saved)
        logger.debug(emptied_current)
        return emptied_current
    else:
        logger.debug(current_slots)
        return current_slots
     
def exit_survey(event):
    userID = event.get('userId')
    intent = event['currentIntent']['name']
    fullfillment_state = 'Fulfilled'
    last_intent = get_last_intent(userID)
    message_content = "Your responses have been saved. Please text 804.251.2876 with '" + last_intent + "' when ready to resume."

    response = {
        'dialogAction': {
            'type': 'Close',
            'fulfillmentState': fullfillment_state,
            'message': {'contentType': 'PlainText', 'content': message_content}
        }
        
    }
    
    logger.debug(response)
    return response

def validate_input(event):
    slots_dict = check_session(event)
    logger.debug(slots_dict)
    try:
        if slots_dict.get('raceOne') == '1' or slots_dict.get('raceOne') == '2' or slots_dict.get('raceOne') == '3':
            slots_1 = {
                'Slots': {
                    'raceTwo': '8',
                    'raceThree': '12'
                }
            }
            s1 = slots_1["Slots"]
            slots_dict.update(s1)
        if slots_dict.get('milStatus') == '1':
            slots_2 = {
                'Slots': {
                    'milStatusTwo': '1',
                    'milService': '5',
                    'milDeployment': '1'
                }
            }
            s2 = slots_2["Slots"]
            slots_dict.update(s2)
        if slots_dict.get('activitySexOne') == '2':
            slots_3 = {
                'Slots': {
                    'activitySexTwo': '1',
                    'activitySexThree': '0',
                    'activitySexFour': '0',
                    'activitySexFive': '0',
                    'activitySexSix': '0'
                }
            }
            s3 = slots_3["Slots"]
            slots_dict.update(s3)
    except ValueError:
        logger.debug(slots_dict)
    else:
        return input_response(slots_dict)
    return input_response(slots_dict)
