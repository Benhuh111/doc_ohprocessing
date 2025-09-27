#!/bin/bash

# Change permissions script for Doc_Ohpp deployment scripts
# This script makes all the deployment scripts executable

echo "Setting executable permissions for deployment scripts..."

# Set permissions for scripts directory
chmod +x /opt/docohpp/scripts/*.sh 2>/dev/null || echo "Scripts directory not found, this is normal during first deployment"

# Set proper ownership and permissions for application directory
chown -R ec2-user:ec2-user /opt/docohpp
chmod 755 /opt/docohpp

# Set permissions for JAR file
chmod 644 /opt/docohpp/*.jar 2>/dev/null || echo "JAR files not found yet"

# Ensure log directory is writable
mkdir -p /opt/docohpp/logs
chown ec2-user:ec2-user /opt/docohpp/logs
chmod 755 /opt/docohpp/logs

echo "Permissions set successfully!"
exit 0
