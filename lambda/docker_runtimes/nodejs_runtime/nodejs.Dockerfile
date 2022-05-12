FROM public.ecr.aws/lambda/python:3.9 AS lambda

ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

RUN yum -y update \
    && yum -y install zip gzip unzip \
    && yum -y install shadow-utils \
    && yum -y install tar.x86_64
    
# AWSCLI
RUN pip3.9 install awscli --upgrade --user \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip  
    
WORKDIR /var/task/

ARG NODE_VERSION=16.15.0
ARG NODE_PACKAGE=node-v$NODE_VERSION-linux-x64
ARG NODE_HOME=/var/task/$NODE_PACKAGE

ENV NODE_PATH $NODE_HOME/lib/node_modules
ENV PATH $NODE_HOME/bin:$PATH

RUN curl https://nodejs.org/dist/v$NODE_VERSION/$NODE_PACKAGE.tar.gz | tar -xzC /var/task/

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash | NVM_DIR="var/task"

# NPM
RUN npm install -g typescript
RUN npm install -g fs
RUN npm install -g aws-sdk
RUN npm install -g path

RUN chmod -R 755 .

WORKDIR $NODE_HOME

ARG LAMBDA_ZIP_NAME="nodejs.zip"

RUN zip -qr9 ${LAMBDA_ZIP_NAME} *    \
    && aws s3 cp ${LAMBDA_ZIP_NAME} s3://pgx-lambda-runtimes/  \
    && rm ${LAMBDA_ZIP_NAME}

RUN aws s3 cp . s3://pgx-lambda-runtime/nodejs --recursive


