import boto3
import os
import email
from time import sleep
import pandas as pd
import glob

# s3 = boto3.resource('s3')

# for bucket in s3.buckets.all():
#   print(bucket.name)

os.chdir({LOCAL_EMAIL_FOLDER})

#Connect to AWS S3 bucket and download emails
s3 = boto3.client('s3')
list = s3.list_objects(Bucket='email-file-processing')['Contents']

for key in list:
    s3.download_file('email-file-processing', key['Key'], key['Key'])

files = os.listdir()

for file in files:
    msg = email.message_from_file(open(file))
    attachment = msg.get_payload()[1]
    filename = attachment.get_filename()
    extension = attachment.get_content_type()
    open(filename, "wb").write(attachment.get_payload(decode=True))
    sleep(3)
    os.remove(file)

#Combine Files
def combine_files():
    extension = 'xls'
    all_filenames = [i for i in glob.glob('*.{}'.format(extension))]

    # combine all files in the list
    combined_csv = pd.concat([pd.read_excel(files, header=3) for files in all_filenames])
    # export to csv
    combined_csv.to_csv("combined_csv.csv", index=False, encoding='utf-8-sig')


combine_files()
