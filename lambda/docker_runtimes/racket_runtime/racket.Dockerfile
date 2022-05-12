FROM public.ecr.aws/lambda/python:3.9 AS lambda

ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

RUN yum -y update \
    && yum -y install zip unzip tar gzip \
    && yum -y install shadow-utils wget
    
# AWSCLI
RUN pip3.9 install awscli --upgrade --user \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip  
    

# Install Racket
WORKDIR /var/task/racket

RUN wget https://download.racket-lang.org/installers/8.5/racket-8.5-x86_64-linux-cs.sh

RUN chmod +x racket-8.5-x86_64-linux-cs.sh

RUN sh racket-8.5-x86_64-linux-cs.sh --in-place --dest /var/task/racket/
RUN rm racket-8.5-x86_64-linux-cs.sh

WORKDIR /var/task/racket
ARG LAMBDA_ZIP_NAME="racket.zip"

#File cleanup
RUN rm -rf doc

#Lambda Permissions
RUN chmod -R 755 .

RUN zip -qr9 ${LAMBDA_ZIP_NAME} *    \
    && aws s3 cp ${LAMBDA_ZIP_NAME} s3://pgx-lambda-runtimes/ \
    && rm ${LAMBDA_ZIP_NAME}

RUN aws s3 cp . s3://pgx-lambda-runtime/racket --recursive || true
