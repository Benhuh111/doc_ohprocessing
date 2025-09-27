#!/bin/bash

# install-dependencies.sh - Install system dependencies for Doc_Ohpp

echo "Installing system dependencies..."

# Update system packages
yum update -y

# Install Java 21 if not present
if ! java -version 2>&1 | grep -q "21"; then
  echo "Installing Java 21..."
  yum install -y java-21-amazon-corretto-devel
else
  echo "Java 21 already installed"
fi

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/docohpp
chown ec2-user:ec2-user /opt/docohpp

# Install CloudWatch agent if needed
if ! command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl &> /dev/null; then
  echo "Installing CloudWatch agent..."
  yum install -y amazon-cloudwatch-agent
fi

echo "System dependencies installed successfully"
exit 0
