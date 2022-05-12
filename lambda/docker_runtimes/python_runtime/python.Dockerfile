FROM public.ecr.aws/lambda/python:3.9 AS lambda

ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

RUN yum -y update \
    && yum -y install zip unzip bzip2\
    && yum -y install shadow-utils wget tar.x86_64 \
    && yum -y install deltarpm python3-dev

# AWSCLI
RUN pip3.9 install awscli --upgrade --user \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm awscliv2.zip  


RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 
RUN yum -y install yum-utils
RUN yum-builddep R -y
RUN yum-config-manager --enable "rhel-*-optional-rpms"
RUN yum install -q -y wget make which

ARG VERSION=4.2.0
ARG R_DIR=/var/task/R

RUN wget -q https://cran.r-project.org/src/base/R-4/R-${VERSION}.tar.gz && \
    mkdir ${R_DIR} && \
    tar -xf R-${VERSION}.tar.gz && \
    mv R-${VERSION}/* ${R_DIR} && \
    rm R-${VERSION}.tar.gz
    
WORKDIR ${R_DIR}    
RUN ./configure --prefix=${R_DIR} --exec-prefix=${R_DIR} --with-libpth-prefix=/var/task/ --enable-R-shlib --with-tcltk=no --with-html=no --with-ICU=no --disable-nls --disable-R-profiling && \
    make
    
RUN /var/task/R/bin/Rscript -e 'install.packages(c("reticulate"), repos="http://cran.r-project.org")'

ENV LD_LIBRARY_PATH="/var/task/R/lib:/var/task/R/library/var/task/R/site-library:$LD_LIBRARY_PATH"
ENV R_HOME="/var/task/R"

WORKDIR /var

RUN python3 -m pip install --upgrade pandas numpy scipy scikit-learn  \
	  scrapy beautifulsoup4 twilio boto3 pytextrank spacy \
	  catboost twython matplotlib simpy rpy2

WORKDIR /var/task/python
RUN cp -r /var/lang/lib/python3.9/site-packages/* .
    
RUN zip -qr9 python-site-packages.zip *    \
    && aws s3 cp python-site-packages.zip s3://pgx-lambda-runtimes/ \
    && rm python-site-packages.zip

RUN aws s3 cp . s3://pgx-lambda-runtime/python --recursive || true

