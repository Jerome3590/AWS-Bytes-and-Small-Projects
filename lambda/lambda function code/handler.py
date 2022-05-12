import json
import subprocess
import logging
import os
import sys


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def run_command(command):
    command_list = command.split(' ')

    try:
        logger.info("Running shell command: \"{}\"".format(command))
        result = subprocess.run(command_list, stdout=subprocess.PIPE);
        logger.info("Command output:\n---\n{}\n---".format(result.stdout.decode('UTF-8')))
    except Exception as e:
        logger.error("Exception: {}".format(e))
        return False

    return True

run_command('/opt/aws s3 sync s3://pgx-lambda-runtime/ /tmp/')
run_command('chmod -R 755 /tmp')

def lambda_handler(event, context):
    run_command('/opt/aws --version')
    run_command('python --version')
    
    print("Directory Under /tmp: ", os.listdir("/tmp"))
    print("Directory Under /tmp/R: ", os.listdir("/tmp/R"))
    print("Directory Under /tmp/racket: ", os.listdir("/tmp/racket"))
    print("Directory Under /tmp/nodejs: ", os.listdir("/tmp/nodejs"))
   
    run_command('/tmp/R/bin/R --version')
    run_command('/tmp/racket/bin/racket --version')
    run_command('/tmp/nodejs/bin/node --version')
   
