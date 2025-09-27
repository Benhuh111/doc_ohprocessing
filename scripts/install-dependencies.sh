#!/bin/bash

# install-dependencies.sh - Install system dependencies for Doc_Ohpp

echo "Installing system dependencies..."

# Update system packages
echo "Updating system packages..."
yum update -y

# Install Java 21
echo "Installing Java 21 Amazon Corretto..."
yum install -y java-21-amazon-corretto-devel

# Verify installation and create proper symlinks
echo "Setting up Java environment..."

# Find the Java installation
JAVA_HOME_DIR=$(find /usr/lib/jvm -name "*java-21*" -type d 2>/dev/null | head -1)

if [ -z "$JAVA_HOME_DIR" ]; then
    echo "Java installation not found, trying alternative installation..."
    # Try installing OpenJDK as fallback
    yum install -y java-21-openjdk-devel
    JAVA_HOME_DIR=$(find /usr/lib/jvm -name "*java-21*" -type d 2>/dev/null | head -1)
fi

if [ -n "$JAVA_HOME_DIR" ]; then
    echo "Java found at: $JAVA_HOME_DIR"
    
    # Create symlinks in /usr/bin
    ln -sf "$JAVA_HOME_DIR/bin/java" /usr/bin/java
    ln -sf "$JAVA_HOME_DIR/bin/javac" /usr/bin/javac
    
    # Set alternatives (this makes java available system-wide)
    alternatives --install /usr/bin/java java "$JAVA_HOME_DIR/bin/java" 1
    alternatives --set java "$JAVA_HOME_DIR/bin/java"
    
    # Set environment variables system-wide
    echo "export JAVA_HOME=$JAVA_HOME_DIR" > /etc/environment
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment
    
    # Set for ec2-user specifically
    echo "export JAVA_HOME=$JAVA_HOME_DIR" >> /home/ec2-user/.bashrc
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /home/ec2-user/.bashrc
    
    # Set for current session
    export JAVA_HOME="$JAVA_HOME_DIR"
    export PATH="$PATH:$JAVA_HOME/bin"
    
else
    echo "ERROR: Could not find Java installation after install attempt"
    echo "Available JVM directories:"
    ls -la /usr/lib/jvm/ 2>/dev/null || echo "No JVM directory found"
    exit 1
fi

# Final verification
echo "Verifying Java installation..."
java -version 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Java installed successfully"
else
    echo "✗ Java installation verification failed"
    # Try with full path
    "$JAVA_HOME_DIR/bin/java" -version 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Java works with full path"
    else
        echo "✗ Java not working even with full path"
        exit 1
    fi
fi

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/docohpp
chown ec2-user:ec2-user /opt/docohpp

# Install CloudWatch agent if needed
if ! command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl &> /dev/null; then
  echo "Installing CloudWatch agent..."
# Install CodeDeploy agent if not present
if ! rpm -qa | grep -q codedeploy-agent; then
    echo "Installing CodeDeploy agent..."
    yum install -y ruby wget
    cd /home/ec2-user
    wget https://aws-codedeploy-eu-north-1.s3.eu-north-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
fi

echo "System dependencies installed successfully"

# Show final status
echo "=== Installation Summary ==="
echo "Java version:"
java -version 2>&1 || echo "Java not in PATH"
echo "Java location: $JAVA_HOME_DIR"
echo "Java executable test:"
ls -la /usr/bin/java 2>/dev/null || echo "No /usr/bin/java symlink"

exit 0
