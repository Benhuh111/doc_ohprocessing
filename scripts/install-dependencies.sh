#!/bin/bash

# install-dependencies.sh - Install system dependencies for Doc_Ohpp

echo "Installing system dependencies..."

# Update system packages
echo "Updating system packages..."
yum update -y

# Detect Amazon Linux version
echo "Detecting system version..."
if grep -q "Amazon Linux 2" /etc/os-release; then
    echo "Detected Amazon Linux 2"
    AL_VERSION="2"
elif grep -q "Amazon Linux release 2023" /etc/os-release; then
    echo "Detected Amazon Linux 2023"
    AL_VERSION="2023"
else
    echo "Detected Amazon Linux (assuming 2)"
    AL_VERSION="2"
fi

# Install Java based on system version
echo "Installing Java..."

if [ "$AL_VERSION" = "2023" ]; then
    # Amazon Linux 2023
    echo "Installing Java 21 for Amazon Linux 2023..."
    yum install -y java-21-amazon-corretto-devel
    
    if [ $? -ne 0 ]; then
        echo "Corretto installation failed, trying OpenJDK..."
        yum install -y java-21-openjdk-devel
    fi
    
elif [ "$AL_VERSION" = "2" ]; then
    # Amazon Linux 2
    echo "Installing Java 21 for Amazon Linux 2..."
    
    # First try to install Amazon Corretto 21
    amazon-linux-extras enable corretto21 2>/dev/null || echo "Corretto21 extra not available"
    yum install -y java-21-amazon-corretto-devel
    
    if [ $? -ne 0 ]; then
        echo "Corretto installation failed, trying alternative methods..."
        
        # Try installing OpenJDK 21
        yum install -y java-21-openjdk-devel
        
        if [ $? -ne 0 ]; then
            echo "OpenJDK 21 not available, installing Java 17 as fallback..."
            amazon-linux-extras enable corretto17 2>/dev/null || echo "Corretto17 extra not available"
            yum install -y java-17-amazon-corretto-devel
            
            if [ $? -ne 0 ]; then
                echo "Installing OpenJDK 17 as final fallback..."
                yum install -y java-17-openjdk-devel
                
                if [ $? -ne 0 ]; then
                    echo "Installing Java 11 as ultimate fallback..."
                    yum install -y java-11-amazon-corretto-devel
                fi
            fi
        fi
    fi
fi

# Find the installed Java
echo "Locating installed Java..."
JAVA_HOME_DIR=""

# Search for Java installations
for pattern in "java-21*" "java-17*" "java-11*" "java-1.8*"; do
    FOUND_DIR=$(find /usr/lib/jvm -name "$pattern" -type d 2>/dev/null | head -1)
    if [ -n "$FOUND_DIR" ] && [ -x "$FOUND_DIR/bin/java" ]; then
        JAVA_HOME_DIR="$FOUND_DIR"
        echo "Found Java at: $JAVA_HOME_DIR"
        break
    fi
done

# If still not found, try alternative locations
if [ -z "$JAVA_HOME_DIR" ]; then
    echo "Searching alternative locations..."
    for dir in /usr/lib/jvm/*; do
        if [ -d "$dir" ] && [ -x "$dir/bin/java" ]; then
            JAVA_HOME_DIR="$dir"
            echo "Found Java at: $JAVA_HOME_DIR"
            break
        fi
    done
fi

if [ -z "$JAVA_HOME_DIR" ]; then
    echo "ERROR: No Java installation found after multiple attempts"
    echo "Available packages:"
    yum search java | grep -E "(openjdk|corretto)" | head -10
    echo "JVM directory contents:"
    ls -la /usr/lib/jvm/ 2>/dev/null || echo "No JVM directory found"
    exit 1
fi

echo "Setting up Java environment for: $JAVA_HOME_DIR"

# Create symlinks in /usr/bin
ln -sf "$JAVA_HOME_DIR/bin/java" /usr/bin/java
ln -sf "$JAVA_HOME_DIR/bin/javac" /usr/bin/javac 2>/dev/null || echo "javac not available"

# Set up alternatives
alternatives --remove-all java 2>/dev/null || true
alternatives --install /usr/bin/java java "$JAVA_HOME_DIR/bin/java" 1
alternatives --set java "$JAVA_HOME_DIR/bin/java"

# Set environment variables
echo "export JAVA_HOME=$JAVA_HOME_DIR" > /etc/environment
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment

# Set for ec2-user
echo "export JAVA_HOME=$JAVA_HOME_DIR" >> /home/ec2-user/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /home/ec2-user/.bashrc
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Verify installation
echo "Verifying Java installation..."
$JAVA_HOME_DIR/bin/java -version 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Java installed successfully"
    
    # Test with symlink
    /usr/bin/java -version 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Java symlink working"
    else
        echo "⚠ Java symlink not working, but full path works"
    fi
else
    echo "✗ Java installation verification failed"
    exit 1
fi

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/docohpp
chown ec2-user:ec2-user /opt/docohpp

# Install CodeDeploy agent if needed (usually pre-installed on Amazon Linux)
if ! rpm -qa | grep -q codedeploy-agent; then
    echo "Installing CodeDeploy agent..."
    yum install -y ruby wget
    cd /tmp
    wget https://aws-codedeploy-eu-north-1.s3.eu-north-1.amazonaws.com/latest/install
    chmod +x ./install
    ./install auto
    service codedeploy-agent start
fi

echo "System dependencies installed successfully"

# Final status
echo "=== Installation Summary ==="
echo "Java Home: $JAVA_HOME_DIR"
echo "Java Version:"
$JAVA_HOME_DIR/bin/java -version 2>&1 | head -1
echo "Java accessible via /usr/bin/java:"
/usr/bin/java -version 2>&1 | head -1 || echo "Not accessible"

exit 0
