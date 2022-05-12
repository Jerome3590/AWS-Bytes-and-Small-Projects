FROM public.ecr.aws/lambda/python:3.9 AS lambda

ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

RUN yum -y update \
    && yum -y install zip unzip 

# Install AWSCLI
RUN pip3.9 install awscli --upgrade --user \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install -i /var/task/aws -b /var/task/aws \
    && rm awscliv2.zip

    
WORKDIR /var/task/aws
ARG AWSCLI_ZIP_NAME="awscli_lambda.zip"

RUN chmod -R 755 .

WORKDIR /var/task/aws/dist

RUN aws s3 cp . s3://pgx-lambda-runtime/awscli --recursive || true

RUN zip -qr9 ${AWSCLI_ZIP_NAME} *    \
    && aws s3 cp ${AWSCLI_ZIP_NAME} s3://pgx-lambda-runtimes/  \
    && aws lambda publish-layer-version --layer-name awscli --zip-file fileb://${AWSCLI_ZIP_NAME} \
    && rm ${AWSCLI_ZIP_NAME}
    