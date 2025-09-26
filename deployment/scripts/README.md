# Deployment Scripts

This directory contains all shell scripts for deploying and managing the Doc_Ohpp application.

## Script Categories

### Application Lifecycle
- `start-app.sh` - Quick start for development/testing
- `start-application.sh` - Production start with background execution
- `stop-application.sh` - Graceful shutdown with process management

### Environment Setup
- `install-dependencies.sh` - Install Java 21, X-Ray daemon, CloudWatch agent
- `change-permissions.sh` - Set executable permissions for all scripts

### Health & Monitoring  
- `validate-service.sh` - Comprehensive health check and validation

## Usage Examples

### First-time Setup
```bash
# Install all dependencies
./install-dependencies.sh

# Set script permissions
./change-permissions.sh
```

### Daily Operations
```bash
# Start application
./start-application.sh

# Check if running properly
./validate-service.sh

# Stop when needed
./stop-application.sh
```

### Development/Testing
```bash
# Quick start for testing
./start-app.sh
```

## Script Locations

All scripts assume the application JAR is located at `/opt/doc_ohpp/Doc_Ohpp-0.0.1-SNAPSHOT.jar` for production use.

For development, scripts can be run from any directory where the JAR file is present.
