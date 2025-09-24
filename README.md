# Doc_Ohpp

Doc_Ohpp is a Spring Boot application designed for document processing, integrating with AWS services such as S3, DynamoDB, and SQS.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client/Web    │    │  Spring Boot    │    │   AWS Services  │
│   Application   │    │   Application   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Upload Document    │                       │
         ├──────────────────────►│                       │
         │                       │                       │
         │                       │ 2. Store File         │
         │                       ├──────────────────────►│ Amazon S3
         │                       │   (docohpp-documents-behu-20250827-001)
         │                       │                       │
         │                       │ 3. Save Metadata      │
         │                       ├──────────────────────►│ DynamoDB
         │                       │   (Doc_Ohpp table)    │
         │                       │                       │
         │                       │ 4. Send Message       │
         │                       ├──────────────────────►│ SQS Queue
         │                       │   (docoh-processing-queue)
         │                       │                       │
         │ 5. Response           │                       │
         │◄──────────────────────┤                       │
         │                       │                       │
```

### Data Flow
1. **Document Upload**: User uploads a document via REST API endpoint
2. **S3 Storage**: Application stores the document file in S3 bucket
3. **Metadata Storage**: Document metadata is saved to DynamoDB table
4. **Queue Message**: Processing message is sent to SQS queue for async processing
5. **Response**: Upload confirmation is returned to the client

### AWS Resources
- **S3 Bucket**: `docohpp-documents-behu-20250827-001` (eu-north-1)
- **DynamoDB Table**: `Doc_Ohpp` with partition key `documentId` (String)
- **SQS Queue**: `docoh-processing-queue` (Standard queue)

## Features

- Spring Boot 3.5.5 (Java 21)
- AWS SDK v2 for S3, DynamoDB, and SQS
- Modular service structure for AWS integrations
- Placeholder for AWS X-Ray tracing

## Project Structure

- `config/` – AWS configuration classes
- `controller/` – REST controllers (e.g., `DocumentController`)
- `model/` – Data models (`Document`, `DocumentMetadata`)
- `service/` – Service classes for S3, DynamoDB, SQS, and document processing
- `test/` – Unit and integration tests

## Getting Started

### Prerequisites
- Java 21 (Amazon Corretto 21 recommended)
- Maven 3.6+
- AWS CLI configured with credentials
- Access to AWS resources (S3, DynamoDB, SQS)

### How to Run Locally

#### 1. Build and Test the Application

First, clean and test the project to ensure everything is working correctly:

```bash
# Clean and run all tests
mvn clean test

# Build the application package
mvn clean package
```

#### 2. Start the Application

Run the Spring Boot application locally:

```bash
# Start the application in development mode
mvn spring-boot:run
```

The application will start on `http://localhost:8080` by default.

#### 3. Test the Endpoints

Once the application is running, test the following endpoints to verify functionality:

**Health Check Endpoint:**
```bash
# Check application health
curl http://localhost:8080/api/documents/health

# Expected response: 200 OK
```

**List Documents Endpoint:**
```bash
# List all documents
curl http://localhost:8080/api/documents

# Expected response: 200 OK with JSON array of documents
```

**Document Statistics Endpoint:**
```bash
# Get document processing statistics
curl http://localhost:8080/api/documents/stats

# Expected response: 200 OK with statistics JSON
```

**Alternative: Test with Web Browser**
You can also test these endpoints by opening them directly in your web browser:
- Health: http://localhost:8080/api/documents/health
- Documents: http://localhost:8080/api/documents  
- Statistics: http://localhost:8080/api/documents/stats

#### 4. Upload Test Document (Optional)

To test the complete document processing workflow:

```bash
# Create a test file
echo "This is a test document for Doc_Ohpp" > test-document.txt

# Upload the document
curl -X POST -F "file=@test-document.txt" http://localhost:8080/api/documents/upload

# Verify the document was processed by checking the list
curl http://localhost:8080/api/documents
```

#### 5. View Application Logs

Monitor the application logs in the terminal where you ran `mvn spring-boot:run` to see:
- AWS service interactions
- Document processing status
- Any errors or warnings

#### Troubleshooting

**Common Issues:**
- **Port 8080 already in use**: Change the port in `application.properties` with `server.port=8081`
- **AWS credentials not found**: Run `aws configure` to set up your credentials
- **AWS services unavailable**: Ensure your IAM role has proper permissions and AWS resources exist

**Quick Build Commands Reference:**
```bash
# Full clean build and test
mvn clean install

# Skip tests during build (faster)
mvn clean package -DskipTests

# Run tests only
mvn test

# Run specific test class
mvn test -Dtest=DocumentControllerTest
```

## Configuration

Application properties can be set in `src/main/resources/application.properties`.

## Testing

Run all tests with:
```sh
  mvn test
```

## AWS Integration

### Prerequisites
Ensure you have the following AWS resources provisioned:
- S3 bucket for document storage
- DynamoDB table for metadata
- SQS queue for message processing
- Proper IAM permissions for your application

### Configuration
Update `src/main/resources/application.properties` with your AWS settings:

```properties
aws.region=eu-north-1
aws.s3.bucket-name=docohpp-documents-behu-20250827-001
aws.dynamodb.table-name=Doc_Ohpp
aws.sqs.queue-name=docoh-processing-queue
```

### Verification
To verify AWS integration is working correctly, run the verification script:

**Windows:**
```cmd
verify-aws-integration.bat
```

**Linux/Mac:**
```bash
./verify-aws-integration.sh
```

This will:
1. Upload a test document
2. Check if the file appears in S3
3. Verify metadata is stored in DynamoDB
4. Confirm SQS message was sent

### Services Integration
- **S3Service**: Handles file upload/download operations
- **DynamoDBService**: Manages document metadata persistence  
- **SQSService**: Sends and receives processing messages
- **DocumentProcessingService**: Orchestrates the complete document workflow

### CodeBuild Configuration

#### Project Details
- **Project Name**: `DocOhpp-Build`
- **Environment**: Amazon Linux 2 (aws/codebuild/amazonlinux2-x86_64-standard:5.0)
- **Runtime**: Java 21 (Amazon Corretto 21)
- **Compute Type**: BUILD_GENERAL1_MEDIUM
- **Service Role**: `DocOhpp-CodeBuild-ServiceRole`

#### Build Configuration
The CodeBuild project is configured to:
- Use the `buildspec.yml` file in the repository root
- Run Maven tests (`mvn test`) to ensure code quality
- Package the application (`mvn package`)
- Create a `deployment/` directory containing:
  - Application JAR file
  - `appspec.yml` for CodeDeploy
  - `scripts/` directory with deployment scripts

#### CloudWatch Logs
- **Log Group**: `/aws/codebuild/DocOhpp-Build`
- **Status**: Enabled for debugging and monitoring
- **Access**: Available in AWS CloudWatch Console

#### Artifacts Configuration
- **Type**: CODEPIPELINE integration
- **Output**: `deployment/` directory with timestamped artifacts
- **Contents**: 
  - `Doc_Ohpp-*.jar` (Spring Boot application)
  - `appspec.yml` (CodeDeploy specification)
  - `scripts/` (Installation and deployment scripts)

#### Build Process Verification
The buildspec.yml ensures the following verification steps:
1. **Environment Setup**: Java 21 Corretto installation and Maven configuration
2. **Test Execution**: `mvn test` runs all unit and integration tests
3. **Build Compilation**: `mvn clean compile` verifies code compiles successfully
4. **Packaging**: `mvn package` creates the deployable JAR file
5. **Artifact Creation**: Copies JAR, appspec.yml, and scripts to deployment directory

#### Usage
- **For CodePipeline**: The project integrates seamlessly with AWS CodePipeline
- **Manual Builds**: Can be triggered manually through AWS Console or CLI
- **Monitoring**: All build logs are available in CloudWatch for troubleshooting

```bash
# Start a manual build (if needed for testing)
aws codebuild start-build --project-name DocOhpp-Build --region eu-north-1
```

### CodeDeploy Configuration

#### Application Details
- **Application Name**: `DocOhpp-Application`
- **Application ID**: `41c4e2d6-9763-4daa-9317-da286e72778c`
- **Compute Platform**: Server (EC2/On-premises)
- **Deployment Strategy**: In-place deployment
- **Deployment Configuration**: `CodeDeployDefault.AllAtOnce`

#### Deployment Group
- **Deployment Group Name**: `DocOhpp-DeploymentGroup`
- **Deployment Group ID**: `071aad0d-db0a-4ba3-b942-5225a77033d6`
- **Service Role**: `DocOhpp-CodeDeploy-ServiceRole`
- **Target Selection**: EC2 instances tagged with `Application=DocOhpp`

#### EC2 Instance Configuration
The deployment targets EC2 instances with the following specifications:

**Instance Requirements:**
- **AMI**: Amazon Linux 2 (latest)
- **Instance Type**: t3.medium (recommended for adequate resources)
- **IAM Instance Profile**: `DocOhpp-EC2-InstanceProfile`
- **Security Group**: Allows inbound access on ports 22 (SSH) and 8080 (application)
- **Tags**: `Application=DocOhpp`, `Environment=production`

**Security Group Rules:**
- Port 22: SSH access for management
- Port 8080: Application access for users/load balancer
- All outbound traffic allowed for AWS service communication

#### Deployment Target Directory
The application deploys to `/opt/docohpp/` with the following structure:
```
/opt/docohpp/
├── Doc_Ohpp-*.jar          # Spring Boot application
├── appspec.yml              # CodeDeploy specification
└── scripts/                 # Deployment lifecycle scripts
    ├── install-dependencies.sh
    ├── start-application.sh
    ├── stop-application.sh
    └── change-permissions.sh
```

#### Application Logs
Application logs are written to `/var/log/docohpp/`:
```
/var/log/docohpp/
├── application.log          # Main application logs
├── startup.log             # Application startup logs
└── error.log               # Error logs
```

#### Required Software Installation
Each EC2 instance must have the following components installed:

**Core Requirements:**
- Java 21 (Amazon Corretto 21)
- CodeDeploy agent (for deployment automation)
- CloudWatch agent (for log collection and monitoring)
- X-Ray daemon (for distributed tracing)

**Installation Script:**
Use the provided `ec2-setup.sh` script to configure new instances:
```bash
# Download and run the setup script on EC2 instance
curl -O https://github.com/Benhuh111/doc_ohprocessing/raw/main/ec2-setup.sh
chmod +x ec2-setup.sh
./ec2-setup.sh
```

#### Deployment Process Verification
After each deployment, run the verification script to ensure everything is working:

**Verification Steps:**
1. **Directory Structure**: Verify `/opt/docohpp` contains JAR, appspec.yml, and scripts
2. **Process Status**: Confirm the Java application process is running
3. **Port Accessibility**: Check that port 8080 is listening
4. **Log Files**: Verify logs are being written to `/var/log/docohpp`
5. **Service Health**: Test application endpoints for responsiveness
6. **AWS Services**: Confirm X-Ray daemon and CloudWatch agent are running

**Run Verification:**
```bash
# Download and run verification script on EC2 instance
curl -O https://github.com/Benhuh111/doc_ohprocessing/raw/main/verify-deployment.sh
chmod +x verify-deployment.sh
./verify-deployment.sh
```

#### Deployment Commands
```bash
# Create a deployment manually (for testing)
aws deploy create-deployment \
  --application-name DocOhpp-Application \
  --deployment-group-name DocOhpp-DeploymentGroup \
  --s3-location bucket=your-artifacts-bucket,key=DocOhpp-artifacts.zip,bundleType=zip \
  --region eu-north-1

# Check deployment status
aws deploy get-deployment --deployment-id <deployment-id> --region eu-north-1

# List deployments
aws deploy list-deployments \
  --application-name DocOhpp-Application \
  --deployment-group-name DocOhpp-DeploymentGroup \
  --region eu-north-1
```

#### Monitoring and Troubleshooting
- **CloudWatch Logs**: Application logs are collected and stored in CloudWatch
- **X-Ray Tracing**: Distributed tracing data is sent to AWS X-Ray
- **CodeDeploy Console**: Deployment status and logs available in AWS Console
- **Instance Logs**: Local logs available in `/var/log/docohpp/` and `/var/log/aws/codedeploy-agent/`

## IAM Roles & Policies

### Overview
The Doc_Ohpp application implements least-privilege IAM roles and policies for secure AWS service access. All roles follow the principle of least privilege, granting only the minimum permissions required for each service to function.

### EC2 Instance Role: `DocOhpp-EC2-InstanceRole`
**Purpose**: Allows EC2 instances running the Doc_Ohpp application to access AWS services.

**Attached Policies**:
- `DocOhpp-S3-Policy`: S3 bucket access for document storage
- `DocOhpp-DynamoDB-Policy`: DynamoDB table operations for metadata
- `DocOhpp-SQS-Policy`: SQS queue messaging operations
- `DocOhpp-XRay-Policy`: X-Ray tracing capabilities
- `DocOhpp-CloudWatch-Policy`: CloudWatch Logs for application logging

**Instance Profile**: `DocOhpp-EC2-InstanceProfile`

#### Specific Permissions:
```
S3 Permissions:
- s3:PutObject, s3:GetObject, s3:DeleteObject on docohpp-documents-behu-20250827-001/*
- s3:ListBucket on docohpp-documents-behu-20250827-001

DynamoDB Permissions:
- dynamodb:PutItem, GetItem, UpdateItem, DeleteItem, Scan on Doc_Ohpp table

SQS Permissions:
- sqs:SendMessage, GetQueueAttributes, ReceiveMessage, DeleteMessage on docoh-processing-queue

X-Ray Permissions:
- xray:PutTraceSegments, xray:PutTelemetryRecords (global)

CloudWatch Permissions:
- logs:CreateLogGroup, CreateLogStream, PutLogEvents on /aws/ec2/docohpp* and /application/docohpp*
```

### CodeBuild Service Role: `DocOhpp-CodeBuild-ServiceRole`
**Purpose**: Allows CodeBuild to build the Doc_Ohpp application from source code.

**Attached Policies**:
- `DocOhpp-CodeBuild-Policy`: Custom policy for build operations

#### Specific Permissions:
```
CloudWatch Logs:
- logs:CreateLogGroup, CreateLogStream, PutLogEvents on /aws/codebuild/docohpp*

S3 Artifacts:
- s3:GetBucketAcl, GetBucketLocation, GetObject, GetObjectVersion, PutObject
- Access to CodePipeline and CodeBuild artifact buckets

Source Code Access:
- codecommit:GitPull for source repository access
- ssm:GetParameters for build parameters
```

### CodeDeploy Service Role: `DocOhpp-CodeDeploy-ServiceRole`
**Purpose**: Allows CodeDeploy to deploy the application to EC2 instances.

**Attached Policies**:
- `DocOhpp-CodeDeploy-Policy`: Custom policy for deployment operations
- `AWSCodeDeployRole`: AWS managed policy for EC2 deployments

#### Specific Permissions:
```
EC2 Access:
- ec2:DescribeInstances, DescribeInstanceStatus
- tag:GetResources for tagged instance discovery

Auto Scaling:
- autoscaling:CompleteLifecycleAction, DeleteLifecycleHook, DescribeLifecycleHooks
- autoscaling:DescribeAutoScalingGroups, PutLifecycleHook, RecordLifecycleActionHeartbeat

Role Management:
- iam:PassRole for DocOhpp-* roles
```

### Security Best Practices Implemented
1. **Least Privilege**: Each role has only the minimum permissions required
2. **Resource-Specific ARNs**: Policies target specific resources rather than using wildcards
3. **Service-Specific Roles**: Separate roles for different services (EC2, CodeBuild, CodeDeploy)
4. **No Cross-Service Access**: Roles cannot access resources outside their intended scope
5. **Regional Restrictions**: Policies are scoped to eu-north-1 region where applicable

### IAM Verification
To verify IAM permissions are working correctly, run the verification script:

**Windows:**
```cmd
verify-iam-permissions.bat
```

This script uses AWS IAM Policy Simulator to validate that:
1. EC2 instances can access S3, DynamoDB, SQS, and X-Ray
2. CodeBuild can access required logging and artifact resources
3. CodeDeploy can manage EC2 deployments

### Usage Instructions
1. **For EC2 Deployment**: Attach the `DocOhpp-EC2-InstanceProfile` to your EC2 instances
2. **For CodeBuild**: Use `DocOhpp-CodeBuild-ServiceRole` as the service role in build projects
3. **For CodeDeploy**: Use `DocOhpp-CodeDeploy-ServiceRole` as the service role in deployment configurations
