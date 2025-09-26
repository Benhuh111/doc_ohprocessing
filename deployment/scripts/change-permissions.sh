#!/bin/bash

# Change permissions script for Doc_Ohpp deployment scripts
# This script makes all the deployment scripts executable

echo "Setting executable permissions for deployment scripts..."

# Set permissions for all shell scripts in the deployment directory
chmod +x /opt/doc_ohpp/deployment/scripts/*.sh

# Set permissions for application scripts
chmod +x /opt/doc_ohpp/start-application.sh
chmod +x /opt/doc_ohpp/stop-application.sh
chmod +x /opt/doc_ohpp/validate-service.sh

# Set permissions for the JAR file
chmod +x /opt/doc_ohpp/*.jar

echo "Permissions set successfully!"
