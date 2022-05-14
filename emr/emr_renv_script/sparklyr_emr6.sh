#!/bin/bash
# Based on earlier work by Tom Zeng
# Updated 11 November 2020 by Peter Schmiedeskamp and Ido Michael
# Last updated 27 November 2021 by Jerome Dixon

set -x -e

# Desired R release version
rver=4.1.2

# Desired R Studio package
rspkg=rstudio-server-rhel-2021.09.2-382-x86_64.rpm

# Password for R Studio user "hadoop"
rspasswd={your_password}

# Check whether we're running on the main node
main_node=false
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
  main_node=true
fi

# update everything
sudo yum update -y

# install some additional R and R package dependencies
sudo yum install -y bzip2-devel cairo-devel \
     gcc gcc-c++ gcc-gfortran libXt-devel \
     libcurl-devel libjpeg-devel libpng-devel \
     pango-devel pango \
     libtiff-devel pcre2-devel readline-devel jq \
     texinfo texlive-collection-fontsrecommended

# Compile R from source; install to /usr/local/*
mkdir /tmp/R-build
cd /tmp/R-build
curl -OL https://cran.r-project.org/src/base/R-4/R-$rver.tar.gz
tar -xzf R-$rver.tar.gz
cd R-$rver
./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr/local --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
make -j 8
sudo make install

# Set some R environment variables for EMR
cat << 'EOF' > /tmp/Renvextra
JAVA_HOME="/etc/alternatives/jre"
HADOOP_HOME_WARN_SUPPRESS="true"
HADOOP_HOME="/usr/lib/hadoop"
HADOOP_PREFIX="/usr/lib/hadoop"
HADOOP_MAPRED_HOME="/usr/lib/hadoop-mapreduce"
HADOOP_YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_COMMON_HOME="/usr/lib/hadoop"
HADOOP_HDFS_HOME="/usr/lib/hadoop-hdfs"
YARN_HOME="/usr/lib/hadoop-yarn"
HADOOP_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"
YARN_CONF_DIR="/usr/lib/hadoop/etc/hadoop/"

HIVE_HOME="/usr/lib/hive"
HIVE_CONF_DIR="/usr/lib/hive/conf"

HBASE_HOME="/usr/lib/hbase"
HBASE_CONF_DIR="/usr/lib/hbase/conf"

SPARK_HOME="/usr/lib/spark"
SPARK_CONF_DIR="/usr/lib/spark/conf"

PATH=${PWD}:${PATH}
EOF
cat /tmp/Renvextra | sudo  tee -a /usr/local/lib64/R/etc/Renviron

# Reconfigure R Java support before installing packages
sudo /usr/local/bin/R CMD javareconf

# Download, verify checksum, and install RStudio Server
# Only install / start RStudio on the main node
if [ "$main_node" = true ]; then
    curl -OL https://download2.rstudio.org/server/centos7/x86_64/$rspkg
    sudo mkdir -p /etc/rstudio
    sudo sh -c "echo 'auth-minimum-user-id=100' >> /etc/rstudio/rserver.conf"
    sudo yum install -y $rspkg
    sudo rstudio-server start
fi

# Set password for hadoop user for R Studio
sudo sh -c "echo '$rspasswd' | passwd hadoop --stdin"


# Install R packages
sudo /usr/local/bin/R --no-save <<R_SCRIPT
Sys.setenv(TZ='America/New_York')
Sys.setenv(LIBARROW_MINIMAL = "false")
install.packages(c('sparklyr','shiny','dplyr','ggplot2','sparklyr','Lahman','sparklyr.nested','sparkxgb'),
repos="http://cran.rstudio.com")
install.packages(c('readxl','tidyverse','DOPE','medExtractR','aws.s3','aws.signature','here','stringr','magrittr'),
repos="http://cran.rstudio.com")
install.packages(c('ggmosaic','forcats','factoMineR','dbplot','reticulate','jsonlite','httr','rvest', 'scales'), 
repos="http://cran.rstudio.com")
install.packages(c('tm','wordcloud','remotes','networkD3','arrow'), repos="http://cran.rstudio.com")
remotes::install_github("nathaneastwood/flicker")
R_SCRIPT

# Install Python packages
sudo python3 -m pip install numpy \
    boto3 ec2-metadata \
    pandas \
    seaborn sagemaker\
    pyspark findspark 
    

# Copy any startup scripts to cluster directory
aws s3 cp s3://{your-s3-bucket}/{any-code}.Rmd ~/