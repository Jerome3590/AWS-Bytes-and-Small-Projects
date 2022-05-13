Hosting AWS Lambda Runtimes in AWS S3

Steps:
1. Docker file to load AWS CLI to Lambda Layer (we want the ‘aws s3 sync’ command in lambda /opt directory)
2. Modify R startup bash script to match AWS Lambda filesystem
3. Docker files to load  R, Racket, NodeJS, and additional Python environments to AWS S3
4. Create Lambda function
5. Add Lambda Layer to Lambda function for AWS CLI capability
6. Add function code (python). Lambda function code will call ‘aws s3 sync’ to copy files to /tmp directory.
7. Modify Lambda function configuration settings to increase ephemeral storage limit 
8. Test function
9. Add EventBridge rule to fire Lambda every 5 minutes to keep ephemeral storage persistent


![Lambda Runtimes Hosted in S3](https://github.com/Jerome3590/AWS-Bytes-and-Small-Projects/blob/main/lambda/AWS%20Lambda%2010%20GB%20Ephemereal%20Storage.png)
