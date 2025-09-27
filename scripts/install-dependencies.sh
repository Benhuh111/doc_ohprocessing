#!/bin/bash

# install-dependencies.sh - Install system dependencies for Doc_Ohpp

echo "Installing system dependencies..."

# Update system packages
yum update -y

# Install Java 21 if not present
echo "Installing Java 21..."
yum install -y java-21-amazon-corretto-devel

# Verify Java installation
echo "Verifying Java installation:"
java -version 2>&1 || echo "Java not found in PATH"

# Find Java installation and create symlink if needed
JAVA_HOME_DIR=$(find /usr/lib/jvm -name "*java-21*corretto*" -type d | head -1)
if [ -n "$JAVA_HOME_DIR" ]; then
  echo "Java installed at: $JAVA_HOME_DIR"
  
  # Create symlink in /usr/bin if java is not there
  if [ ! -L /usr/bin/java ]; then
    ln -sf "$JAVA_HOME_DIR/bin/java" /usr/bin/java
    echo "Created symlink for java command"
  fi
  
  # Set JAVA_HOME for all users
  echo "export JAVA_HOME=$JAVA_HOME_DIR" > /etc/environment
  echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment
  
  # Add to profile for immediate effect
  echo "export JAVA_HOME=$JAVA_HOME_DIR" >> /home/ec2-user/.bashrc
  echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /home/ec2-user/.bashrc
else
  echo "Warning: Could not locate Java installation directory"
fi

# Verify java is accessible
echo "Final Java verification:"
/usr/bin/java -version 2>&1 || echo "Java still not accessible via /usr/bin/java"

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
