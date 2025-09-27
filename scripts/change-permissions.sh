#!/bin/bash

# Change permissions script for Doc_Ohpp deployment scripts
# This script makes all the deployment scripts executable

echo "Setting executable permissions for deployment scripts..."

# Set permissions for all shell scripts in the scripts directory
chmod +x /opt/docohpp/scripts/*.sh

# Set proper ownership
chown -R ec2-user:ec2-user /opt/docohpp

echo "Permissions set successfully!"
exit 0
