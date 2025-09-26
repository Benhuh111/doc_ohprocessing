#!/bin/bash

# Install dependencies script for Doc_Ohpp Spring Boot application
# This script installs Java 21 and other required dependencies

echo "Installing dependencies for Doc_Ohpp application..."

# Update package manager
sudo yum update -y

# Install Java 21
echo "Installing Java 21..."
sudo yum install -y java-21-amazon-corretto-devel

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
echo 'export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

# Install AWS X-Ray daemon
echo "Installing AWS X-Ray daemon..."
curl https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.rpm -o /tmp/xray.rpm
sudo yum install -y /tmp/xray.rpm

# Create application directory
sudo mkdir -p /opt/doc_ohpp
sudo chown ec2-user:ec2-user /opt/doc_ohpp

# Install CloudWatch agent (optional but recommended)
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

echo "Dependencies installation completed!"
echo "Please log out and log back in to refresh your environment variables."
