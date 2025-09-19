echo "Installing system dependencies..."

# Update system packages
yum update -y

# Install Java 21 if not present
if ! command -v java &> /dev/null || ! java -version 2>&1 | grep -q "21"; then
    echo "Installing Amazon Corretto 21..."
    yum install -y java-21-amazon-corretto
else
    echo "Java 21 already installed"
fi

# Install CloudWatch agent if not present
if ! command -v /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl &> /dev/null; then
    echo "Installing CloudWatch agent..."
    yum install -y amazon-cloudwatch-agent
else
    echo "CloudWatch agent already installed"
fi

# Install X-Ray daemon if not present
if ! command -v xray &> /dev/null; then
    echo "Installing AWS X-Ray daemon..."
    yum install -y aws-xray-daemon
else
    echo "X-Ray daemon already installed"
fi

# Create application directories
mkdir -p /opt/docohpp/logs
mkdir -p /var/log/docohpp

# Set up log rotation
cat > /etc/logrotate.d/docohpp << 'EOF'
/var/log/docohpp/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
}
EOF

echo "Dependencies installation completed"