# Doc_Ohpp Project Structure 1

This document outlines the organization of the Doc_Ohpp project files.

## Root Directory Structure

```
Doc_Ohpp/
├── src/                           # Source code
│   ├── main/
│   │   ├── java/                  # Java source files
│   │   └── resources/             # Application resources
│   └── test/                      # Test files
├── deployment/                    # Deployment configurations
│   ├── aws-codedeploy/           # AWS CodeDeploy scripts
│   ├── aws-codepipeline/         # AWS CodePipeline templates
│   ├── iam-policies/             # AWS IAM policy definitions
│   ├── scripts/                  # Deployment shell scripts
│   └── step-functions/           # AWS Step Functions definitions
├── docs/                         # Project documentation
├── target/                       # Maven build output (generated)
├── .mvn/                         # Maven wrapper files
├── pom.xml                       # Maven project configuration
├── appspec.yml                   # AWS CodeDeploy application spec
├── buildspec.yml                 # AWS CodeBuild build spec
├── Procfile                      # Process file for deployment platforms
└── README.md                     # Main project documentation
```

## Key Directories

### `/src`
Contains all source code and resources:
- `main/java/` - Java application code
- `main/resources/` - Configuration files, static web content
- `test/` - Unit and integration tests

### `/deployment`
Contains all deployment-related files:
- `scripts/` - Shell scripts for application lifecycle management
- `aws-*` - AWS-specific deployment configurations
- `iam-policies/` - AWS IAM policy definitions

### `/docs`
Project documentation and guides

## Deployment Scripts

All deployment scripts are located in `deployment/scripts/`:
- `start-app.sh` - Quick start script for EC2
- `start-application.sh` - Production start script
- `stop-application.sh` - Stop application script
- `install-dependencies.sh` - Install system dependencies
- `validate-service.sh` - Validate application health
- `change-permissions.sh` - Set file permissions
