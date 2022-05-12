FROM public.ecr.aws/lambda/python:3.9 AS lambda

ENV AWS_DEFAULT_REGION=us-east-1
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}


RUN yum -y update \
    && yum -y install zip unzip bzip2\
    && yum -y install shadow-utils wget tar.x86_64
RUN yum -y install deltarpm

    
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
RUN yum install -q -y wget xorg-x11-server-devel libX11-devel libXt-devel \
    curl-devel gcc-c++ gcc-gfortran zlib-devel bzip2 bzip2-libs java-1.8.0-openjdk-devel
RUN yum -y install libgit2-devel libxml2-devel openssl-devel pcre2-devel make which
RUN yum -y install v8-devel cairo-devel qt5-qtsvg  fontconfig-devel


ARG VERSION=4.2.0
ARG R_DIR=/var/task/R

RUN wget -q https://cran.r-project.org/src/base/R-4/R-${VERSION}.tar.gz && \
    mkdir ${R_DIR} && \
    tar -xf R-${VERSION}.tar.gz && \
    mv R-${VERSION}/* ${R_DIR} && \
    rm R-${VERSION}.tar.gz

WORKDIR ${R_DIR}
RUN ./configure --prefix=${R_DIR} --exec-prefix=${R_DIR} --with-libpth-prefix=/var/task/ --enable-R-shlib --with-tcltk=no --with-ICU=no --with-html=no --disable-nls --disable-R-profiling && \
    make

RUN /var/task/R/bin/Rscript -e 'install.packages(c("httr", "aws.signature", "aws.s3", \
  "jsonlite", "logging", "xml2"), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("magrittr", "data.table", "tidyverse", \     
  "lubridate", "readxl", "readr", "reshape2", "purrr"), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("git2r", "metaSEM", "bupaR", "deSolve", \        
  "ggplot2", "gtable", "kableExtra"), repos="http://cran.r-project.org")'
  
RUN /var/task/R/bin/Rscript -e 'install.packages(c("reticulate", "keras", "caret", "lightgbm"), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("networkD3", "htmlwidgets", "gpboost"), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("xgboost", "paws", "OpenMx", "logging" ), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("littler", "umx", "shiny", "stringi", "stringr" ), repos="http://cran.r-project.org")'

RUN /var/task/R/bin/Rscript -e 'install.packages(c("tidyr", "markdown", "rvest", "rlist", "qpcR", "rCBA" ), repos="http://cran.r-project.org")'

	
RUN wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN tar xjvf phantomjs-2.1.1-linux-x86_64.tar.bz2
RUN rm phantomjs-2.1.1-linux-x86_64.tar.bz2


RUN cp /lib64/ld-linux-x86-64*  /var/task/R/lib
RUN cp /lib64/libpthread*  /var/task/R/lib
RUN cp /lib64/libc*  /var/task/R/lib
RUN cp /lib64/libgomp*  /var/task/R/lib
RUN cp /usr/lib64/libgfortran*  /var/task/R/lib
RUN cp /lib64/libquadmath*  /var/task/R/lib
RUN cp /lib64/libpcre*  /var/task/R/lib

RUN aws s3 cp s3://pgx-lambda-runtimes/R_Startup_Script/R /var/task/R

RUN aws s3 cp s3://pgx-lambda-runtimes/R_Startup_Script/R /var/task/R/bin/

#File cleanup
RUN rm -r doc/*
RUN rm -r m4/*
RUN rm -r po/*
RUN rm -r src/*
RUN rm -r tests/*
RUN rm -r include/*
RUN rm -r modules/*
RUN rm -r share/*
RUN rm -r tools/*
RUN rm config*
RUN rm Make*
RUN rm VERSION*
RUN rm Change*
RUN rm COPYING INSTALL README stamp-java SVN-REVISION libtool


RUN chmod -R 755 .


ARG LAMBDA_ZIP_NAME="r_runtime.zip"

RUN zip -qr9 ${LAMBDA_ZIP_NAME} *    \
    && aws s3 cp ${LAMBDA_ZIP_NAME} s3://pgx-lambda-runtimes/ \
    && rm ${LAMBDA_ZIP_NAME}

RUN aws s3 cp . s3://pgx-lambda-runtime/R --recursive || true
