#!/bin/bash
#
# RStudio with Cytoscape Install

set -x -e

# Desired R release version
rver=4.1.2

# Desired R Studio package
rspkg=rstudio-2021.09.2-382-x86_64.rpm

# Add Users
sudo  useradd ${user1}
sudo  useradd ${user2}

# Password users 
rspasswd1=${password_user1}
rspasswd2=${password_user2}

# Set passwords for users for R Studio
sudo sh -c "echo '$rspasswd1' | passwd ${user1} --stdin"
sudo sh -c "echo '$rspasswd2' | passwd ${user2} --stdin"

# update everything
sudo yum update -y

# install some additional R and R package dependencies
sudo yum install -y bzip2-devel cairo-devel \
     gcc gcc-c++ gcc-gfortran libXt-devel \
     libcurl-devel libjpeg-devel libpng-devel \
     libtiff-devel pcre2-devel readline-devel jq \
     texinfo texlive-collection-fontsrecommended \
	 java-11-openjdk-devel

# Compile R from source; install to /usr/local/*
mkdir /tmp/R-build
cd /tmp/R-build
curl -OL https://cran.r-project.org/src/base/R-4/R-$rver.tar.gz
tar -xzf R-$rver.tar.gz
cd R-$rver
./configure --with-readline=yes --enable-R-profiling=no --enable-memory-profiling=no --enable-R-shlib --with-pic --prefix=/usr/local --with-x --with-libpng --with-jpeglib --with-cairo --enable-R-shlib --with-recommended-packages=yes
make -j 8
sudo make install

# Reconfigure R Java support before installing packages
sudo /usr/local/bin/R CMD javareconf

# Install RStudio
curl -OL https://download1.rstudio.org/desktop/centos7/x86_64/$rspkg

sudo mkdir -p /etc/rstudio
sudo yum install -y $rspkg
sudo rstudio-server start


# Install R packages
sudo /usr/local/bin/R --no-save <<R_SCRIPT
Sys.setenv(TZ='America/New_York')
install.packages(c('shiny','dplyr','ggplot2','rjava'),
repos="http://cran.rstudio.com")
install.packages(c('readxl','tidyverse','DOPE','medExtractR','aws.s3','aws.signature','here','stringr','magrittr'),
repos="http://cran.rstudio.com")
install.packages(c('ggmosaic','forcats','factoMineR','dbplot','reticulate','jsonlite','httr','rvest'), 
repos="http://cran.rstudio.com")
R_SCRIPT

# Install Mate GUI with TigerVNC
sudo amazon-linux-extras install mate-desktop1.x
sudo amazon-linux-extras install python3.8
sudo bash -c 'echo PREFERRED=/usr/bin/mate-session > /etc/sysconfig/desktop'
sudo yum install tigervnc-server
#vncpasswd

sudo bash -c 'echo localhost > /etc/tigervnc/vncserver-config-mandatory'
sudo cp /lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service
sudo sed -i 's/<USER>/ec2-user/' /etc/systemd/system/vncserver@.service
sudo sed -i 's/<USER>/${user1}/' /etc/systemd/system/vncserver@.service
sudo sed -i 's/<USER>/${user2}/' /etc/systemd/system/vncserver@.service
echo SecurityTypes=None >> ~/.vnc/config
sudo systemctl daemon-reload
sudo systemctl enable vncserver@:1
sudo systemctl start vncserver@:1

# Connect via SSH
# ssh -L 5901:localhost:5901 -i "${ssh-key-pem}" ec2-user@${ip-address-ec2}.compute-1.amazonaws.com

# vncviewer http://${ec2-ip-address}:5901/


# Install Cytoscape
wget https://github.com/cytoscape/cytoscape/releases/download/3.9.0/Cytoscape_3_9_0_unix.sh
bash ./Cytoscape_3_9_0_unix.sh -q


# Install Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
