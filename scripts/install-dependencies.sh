#!/bin/bash

# install-dependencies.sh - Install Java 21 specifically for Doc_Ohpp

echo "Installing system dependencies..."

# Update system packages
echo "Updating system packages..."
yum update -y

# Install prerequisite packages
yum install -y wget tar gzip

echo "Installing Java 21..."

# Method 1: Try Amazon Corretto 21 direct download
echo "Attempting to install Amazon Corretto 21..."
cd /tmp

# Download Amazon Corretto 21
CORRETTO_URL="https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.tar.gz"
echo "Downloading from: $CORRETTO_URL"

wget -O corretto-21.tar.gz "$CORRETTO_URL"

if [ $? -eq 0 ] && [ -s corretto-21.tar.gz ]; then
    echo "Successfully downloaded Corretto 21"
    
    # Remove any existing Java installations in /opt/java
    rm -rf /opt/java
    mkdir -p /opt/java
    
    # Extract to /opt/java
    tar -xzf corretto-21.tar.gz -C /opt/java --strip-components=1
    
    if [ -x /opt/java/bin/java ]; then
        JAVA_HOME_DIR="/opt/java"
        echo "✓ Amazon Corretto 21 installed to $JAVA_HOME_DIR"
    else
        echo "✗ Extraction failed"
        exit 1
    fi
    
else
    echo "Corretto download failed, trying alternative method..."
    
    # Method 2: Try OpenJDK 21
    yum install -y java-21-openjdk-devel 2>/dev/null
    
    if [ $? -eq 0 ]; then
        JAVA_HOME_DIR=$(find /usr/lib/jvm -name "*java-21*" -type d | head -1)
        if [ -n "$JAVA_HOME_DIR" ] && [ -x "$JAVA_HOME_DIR/bin/java" ]; then
            echo "✓ OpenJDK 21 installed to $JAVA_HOME_DIR"
        else
            echo "✗ OpenJDK 21 installation failed"
            exit 1
        fi
    else
        echo "✗ All Java 21 installation methods failed"
        exit 1
    fi
fi

# Verify we have Java 21
echo "Verifying Java 21 installation..."
JAVA_VERSION_OUTPUT=$($JAVA_HOME_DIR/bin/java -version 2>&1)
echo "Java version output:"
echo "$JAVA_VERSION_OUTPUT"

if echo "$JAVA_VERSION_OUTPUT" | grep -q "21\." || echo "$JAVA_VERSION_OUTPUT" | grep -q "21+"; then
    echo "✓ Java 21 confirmed"
else
    echo "✗ Wrong Java version installed"
    echo "Expected: Java 21"
    echo "Got: $JAVA_VERSION_OUTPUT"
    exit 1
fi

echo "Setting up Java 21 as system default..."

# Remove old alternatives and symlinks
alternatives --remove-all java 2>/dev/null || true
rm -f /usr/bin/java /usr/bin/javac

# Create new symlinks
ln -sf "$JAVA_HOME_DIR/bin/java" /usr/bin/java
ln -sf "$JAVA_HOME_DIR/bin/javac" /usr/bin/javac

# Set up alternatives with high priority
alternatives --install /usr/bin/java java "$JAVA_HOME_DIR/bin/java" 100
alternatives --set java "$JAVA_HOME_DIR/bin/java"

# Set environment variables
echo "export JAVA_HOME=$JAVA_HOME_DIR" > /etc/environment
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/environment

# Set for ec2-user
cat > /home/ec2-user/.java_env << EOF
export JAVA_HOME=$JAVA_HOME_DIR
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

# Add to .bashrc
echo "source ~/.java_env" >> /home/ec2-user/.bashrc
chown ec2-user:ec2-user /home/ec2-user/.java_env /home/ec2-user/.bashrc

# Final verification
echo "=== Final Java Verification ==="
echo "Java Home: $JAVA_HOME_DIR"

echo "Direct Java version check:"
$JAVA_HOME_DIR/bin/java -version 2>&1

echo "Symlink Java version check:"
/usr/bin/java -version 2>&1

echo "Alternatives Java version check:"
alternatives --display java 2>/dev/null || echo "No alternatives found"

# Test that it's really Java 21
FINAL_VERSION=$(/usr/bin/java -version 2>&1 | head -1)
if echo "$FINAL_VERSION" | grep -q "21\." || echo "$FINAL_VERSION" | grep -q "21+"; then
    echo "✅ Java 21 is properly configured system-wide"
else
    echo "❌ System Java is not version 21: $FINAL_VERSION"
    exit 1
fi

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/docohpp
chown ec2-user:ec2-user /opt/docohpp

echo "✅ Java 21 installation completed successfully"
exit 0
