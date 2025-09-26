# Deployment Guide

This directory contains all deployment configurations and scripts for the Doc_Ohpp application.

## Directory Structure

```
deployment/
├── aws-codedeploy/          # AWS CodeDeploy configurations
├── aws-codepipeline/        # AWS CodePipeline templates  
├── iam-policies/            # AWS IAM policy definitions
├── scripts/                 # Deployment and lifecycle scripts
└── step-functions/          # AWS Step Functions workflows
```

## Quick Deployment (EC2)

### Prerequisites
1. EC2 instance running Amazon Linux 2
2. Java 21 installed
3. AWS CLI configured with appropriate permissions
4. Application JAR file uploaded to `/home/ec2-user/`

### Deployment Steps

1. **Install dependencies** (first time only):
   ```bash
   ./scripts/install-dependencies.sh
   ```

2. **Set permissions**:
   ```bash
   ./scripts/change-permissions.sh
   ```

3. **Start application**:
   ```bash
   ./scripts/start-application.sh
   ```

4. **Validate deployment**:
   ```bash
   ./scripts/validate-service.sh
   ```

5. **Stop application** (when needed):
   ```bash
   ./scripts/stop-application.sh
   ```

## Script Descriptions

| Script | Purpose |
|--------|---------|
| `start-app.sh` | Quick start script for development/testing |
| `start-application.sh` | Production start script with background execution |
| `stop-application.sh` | Graceful application shutdown |
| `install-dependencies.sh` | Install Java, X-Ray daemon, and other dependencies |
| `validate-service.sh` | Health check and validation |
| `change-permissions.sh` | Set executable permissions for scripts |

## AWS CodeDeploy

The application is configured for AWS CodeDeploy deployment using:
- `appspec.yml` (root directory)
- Scripts in `aws-codedeploy/` directory
- IAM policies in `iam-policies/` directory

## Environment Configuration

The application supports multiple environments:
- **Local**: `--spring.profiles.active=local`
- **Development**: `--spring.profiles.active=dev`  
- **Production**: `--spring.profiles.active=prod`

## Monitoring

- **AWS X-Ray**: Distributed tracing enabled
- **CloudWatch**: Logs and metrics collection
- **Application Logs**: Available at `/opt/doc_ohpp/application.log`

## Troubleshooting

1. **Port 8080 in use**: 
   ```bash
   sudo netstat -tlnp | grep :8080
   kill [PID]
   ```

2. **Check application logs**:
   ```bash
   tail -f /opt/doc_ohpp/application.log
   ```

3. **Validate AWS resources**:
   ```bash
   aws s3 ls
   aws dynamodb list-tables
   aws sqs list-queues
   ```
