#!/bin/bash
# EC2 Instance Setup Script for Doc_Ohpp CodeDeploy
echo "=== Doc_Ohpp EC2 Instance Setup ==="

# Update the system
echo "Updating system packages..."
sudo yum update -y

# Install Java 21 (Amazon Corretto)
echo "Installing Java 21 (Amazon Corretto)..."
sudo yum install -y java-21-amazon-corretto

# Install CodeDeploy agent
echo "Installing CodeDeploy agent..."
sudo yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Start and enable CodeDeploy agent
echo "Starting CodeDeploy agent..."
sudo service codedeploy-agent start
sudo chkconfig codedeploy-agent on

# Install CloudWatch agent
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm

# Install X-Ray daemon
echo "Installing X-Ray daemon..."
wget https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-linux-3.x.zip
unzip aws-xray-daemon-linux-3.x.zip
sudo cp xray /usr/local/bin/
sudo chmod +x /usr/local/bin/xray

# Create X-Ray daemon service
echo "Creating X-Ray daemon service..."
sudo tee /etc/systemd/system/xray.service > /dev/null <<EOF
[Unit]
Description=AWS X-Ray Daemon
After=network.target

[Service]
Type=simple
User=xray
ExecStart=/usr/local/bin/xray -o -n us-east-1
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create xray user
sudo useradd --system --shell /sbin/nologin xray

# Start and enable X-Ray daemon
sudo systemctl daemon-reload
sudo systemctl start xray
sudo systemctl enable xray

# Create application directory
echo "Creating application directory..."
sudo mkdir -p /opt/docohpp
sudo mkdir -p /var/log/docohpp
sudo chown ec2-user:ec2-user /opt/docohpp
sudo chown ec2-user:ec2-user /var/log/docohpp

# Install additional tools
echo "Installing additional tools..."
sudo yum install -y htop curl

# Verify installations
echo "=== Verifying Installations ==="
echo "Java version:"
java -version

echo "CodeDeploy agent status:"
sudo service codedeploy-agent status

echo "X-Ray daemon status:"
sudo systemctl status xray --no-pager

echo "CloudWatch agent installed:"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl --version

echo "=== Setup Complete ==="
echo "Instance is ready for CodeDeploy deployments"
echo "Application will be deployed to: /opt/docohpp"
echo "Logs will be written to: /var/log/docohpp"
