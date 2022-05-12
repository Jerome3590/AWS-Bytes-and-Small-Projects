# Create EC2 instance 

sudo su
sudo yum install docker gnupg2 pass awscli

# Install Python 3.8 system-global 
amazon-linux-extras enable python3.8 

sudo yum -y install python38 
#AWS configure - uninstall awscli version1/install awscli version2 
sudo rm -rf /usr/local/aws 
sudo rm /usr/bin/aws 
pip3.8 install awscli --upgrade --user 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
unzip awscliv2.zip 
sudo ./aws/install 
/usr/local/bin/aws configure 

sudo mkdir lambda-R
sudo chmod -R a+rwx lambda-R
cd lambda-R

sudo systemctl start docker

#[R script]
/usr/local/bin/aws s3 cp s3://function-code/example.R example.R

#[bootstrap code]
/usr/local/bin/aws s3 cp s3://function-code/bootstrap bootstrap


# Docker push to ECR
/usr/local/bin/aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 535362115856.dkr.ecr.us-east-1.amazonaws.com

sudo docker build -t r-refresh -f Dockerfile.playbook .

sudo docker tag r-refresh:latest 535362115856.dkr.ecr.us-east-1.amazonaws.com/r-refresh:latest

sudo docker push 535362115856.dkr.ecr.us-east-1.amazonaws.com/r-refresh:latest
