import json
import boto3
import logging
from boto3.dynamodb.conditions import Key
import pandas as pd
import io
import os


logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

os.chdir('/tmp/')

s3_resource = boto3.resource("s3")
s3_client = boto3.client("s3")

# ---Main Handler---
def lambda_handler(event, context):
    logger.debug(event)
    
    try:
        for record in event['Records']:
    
            lex_data = event['Records'][0]['dynamodb']['NewImage']['Slots']['M']
            lex_survey_type = event['Records'][0]['dynamodb']['NewImage']['IntentName']['S']
            lex_userID = event['Records'][0]['dynamodb']['NewImage']['UserID']['S']
            lex_survey_date = event['Records'][0]['dynamodb']['ApproximateCreationDateTime']
    
            file_obj = s3_client.get_object(Bucket='dbhds-lex-files', Key='GPRA_CodeBook.xlsx')
            file_content = file_obj["Body"].read()
    
            read_excel_data = io.BytesIO(file_content)
            df = pd.ExcelFile(read_excel_data)
    
            sheet_to_df_map = {}
            for sheet_name in df.sheet_names:
                sheet_to_df_map[sheet_name] = df.parse(sheet_name)
    
            x1 = sheet_to_df_map['CSAT_AWS_Lex_Join']
            x1d = x1.drop(['User_Response'], axis=1)
    
            lex_df = pd.DataFrame.from_dict(lex_data)
            lex_dft = lex_df.T
            lex_dftm = lex_dft.reset_index()
            lex_dftm.columns = ['Lex_Data_Element', 'User_Response']
    
            clinician_df1 = pd.merge(x1d, lex_dftm, how='left', on='Lex_Data_Element')
    
            x2 = sheet_to_df_map['CSAT Data Download (Codebook)']
            x2d = x2.drop(x2.index[0:1])
            x2dm = x2.reset_index()
            x2dm.columns = ['index', 'CSAT_Data_Element', 'Question Number', 'Question and/or Description',
                            'Value Definitions', 'Code Book Warning Edits/Skip Logic', 'SlotKey', 'User_Response',
                            'CSAT_Value',
                            'Clinician_Comments']
    
            clinician_df2 = pd.merge(clinician_df1, x2dm, how='left', on='CSAT_Data_Element')
    
            clinician_df_final = clinician_df2.drop(
                ['index', 'Question Number', 'Code Book Warning Edits/Skip Logic', 'SlotKey', 'User_Response_y',
                 'CSAT_Value'], axis=1)
    
            clinician_df_final.at[2, 'User_Response_x'] = pd.to_datetime(lex_survey_date, unit='s')
            clinician_df_final.at[5, 'User_Response_x'] = lex_userID
            clinician_df_final.at[6, 'User_Response_x'] = lex_survey_type
    
            if lex_survey_type == 'test':
                clinician_df_final.at[2, 'User_Response_x'] = pd.to_datetime(lex_survey_date, unit='s')
    
            if lex_survey_type == 'intake':
                clinician_df_final.at[2, 'User_Response_x'] = pd.to_datetime(lex_survey_date, unit='s')
    
            if lex_survey_type == 'discharge':
                clinician_df_final.at[3, 'User_Response_x'] = pd.to_datetime(lex_survey_date, unit='s')
    
            if lex_survey_type == 'follow_up':
                clinician_df_final.at[4, 'User_Response_x'] = pd.to_datetime(lex_survey_date, unit='s')
    
            clinician_df_final.drop(index=0, axis=1)

            clinician_df_final.to_csv(lex_userID + '.csv')

            s3_client.upload_file(lex_userID + '.csv', 'dbhds-lex-files', 'western-tidewater/' + lex_userID + '.csv')


    except Exception as e:
        print(e)
        logger.debug(event)
