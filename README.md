# Doc_Ohpp - Document Processing Application

A Spring Boot application for document processing with AWS integration including S3, DynamoDB, SQS, X-Ray tracing, and CloudWatch monitoring.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Spring Boot   │───▶│   Amazon S3     │    │   Amazon SQS    │
│   Application   │    │   (Documents)   │    │   (Processing)  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         │
         ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   DynamoDB      │    │   AWS X-Ray     │    │   CloudWatch    │
│   (Metadata)    │    │   (Tracing)     │    │   (Monitoring)  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

- Java 21 (Amazon Corretto)
- Maven 3.6+
- AWS CLI configured with appropriate credentials
- AWS Account with necessary permissions

## AWS Resources Setup

### 1. S3 Bucket
- **Name**: `doc-ohpp-documents-bucket` (or update `application.properties`)
- **Purpose**: Store uploaded documents
- **Policy**: Apply bucket policy to restrict access to application role

### 2. DynamoDB Table
- **Table Name**: `Doc_Ohpp`
- **Partition Key**: `documentId` (String)
- **Purpose**: Store document metadata and processing status

### 3. SQS Queue
- **Queue Name**: `docoh-processing-queue`
- **Type**: Standard Queue
- **Purpose**: Handle asynchronous document processing

## How to Run Locally

### Build and Test
```bash
mvn clean test
mvn clean package
```

### Run the Application
```bash
mvn spring-boot:run
```

### Test Endpoints
- Health Check: `GET http://localhost:8080/api/documents/health` → 200
- List Documents: `GET http://localhost:8080/api/documents` → 200
- Statistics: `GET http://localhost:8080/api/documents/stats` → 200

## EC2 Instance Launch Process

### Step 1: Launch EC2 Instance

1. **Launch Instance**:
   - AMI: Amazon Linux 2
   - Instance Type: t3.micro (or larger for production)
   - Security Group: Allow inbound traffic on port 8080 from your IP/ALB
   - Key Pair: Select your key pair for SSH access

2. **Add Tags** (Required for CodeDeploy targeting):
   ```
   Key: Application    Value: DocOhpp
   Key: Environment    Value: production
   ```

3. **IAM Role**: Attach the EC2 instance role with policies:
   - `docohpp-s3-policy.json`
   - `docohpp-dynamodb-policy.json`
   - `docohpp-sqs-policy.json`
   - `docohpp-xray-policy.json`
   - `docohpp-cloudwatch-policy.json`

### Step 2: Configure EC2 Instance

**SSH into your instance:**
```bash
ssh -i your-key.pem ec2-user@your-ec2-public-ip
```

**Download and run the setup script:**
```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Benhuh111/doc_ohprocessing/main/ec2-setup.sh

# Make it executable
chmod +x ec2-setup.sh

# Run the setup script
./ec2-setup.sh
```

**What the setup script installs:**
- ✅ Java 21 (Amazon Corretto)
- ✅ CodeDeploy Agent (configured and running)
- ✅ CloudWatch Agent (for monitoring)
- ✅ X-Ray Daemon (for distributed tracing)
- ✅ Application directories (`/opt/docohpp`, `/var/log/docohpp`)
- ✅ System service configurations

### Step 3: Verify Installation

**Download and run the verification script:**
```bash
# Download the verification script
curl -O https://raw.githubusercontent.com/Benhuh111/doc_ohprocessing/main/verify-deployment.sh

# Make it executable
chmod +x verify-deployment.sh

# Run verification
./verify-deployment.sh
```

**Expected verification results:**
- ✅ CodeDeploy agent running
- ✅ X-Ray daemon active
- ✅ Java 21 installed
- ✅ Application directories created
- ✅ Proper permissions set

## CodeBuild Configuration

### Project Settings
- **Project Name**: `doc-ohpp-build`
- **Environment**: 
  - Managed image: Amazon Linux 2
  - Runtime: Java 21 (Amazon Corretto)
- **Buildspec**: Uses `buildspec.yml` from repository
- **Artifacts**: Outputs to `deployment/` directory containing:
  - JAR file
  - `appspec.yml`
  - Deployment scripts

### Build Verification
- ✅ Maven tests pass
- ✅ JAR file created successfully
- ✅ Deployment artifacts generated
- ✅ CloudWatch logs available for debugging

## CodeDeploy Configuration

### Application Settings
- **Application Name**: `DocOhpp`
- **Compute Platform**: EC2/On-premises
- **Deployment Configuration**: `CodeDeployDefault.HalfAtATime` (In-place deployment)

### Deployment Group Settings
- **Deployment Group Name**: `DocOhpp-Production`
- **Service Role**: `arn:aws:iam::{YOUR-ACCOUNT-ID}:role/codedeploy-service-role`
- **Target Type**: Amazon EC2 instances
- **Tag Filters**:
  ```
  Key: Application    Value: DocOhpp
  Key: Environment    Value: production
  ```

### Deployment Strategy
- **Type**: In-place deployment
- **Configuration**: `CodeDeployDefault.HalfAtATime`
- **Behavior**: Deploys to half of the instances at a time, ensuring high availability during deployments

### Deployment Process
1. Application files deployed to `/opt/docohpp/`
2. Scripts executed from `scripts/` directory:
   - `stop-application.sh` - Stops existing application
   - `install-dependencies.sh` - Installs/updates dependencies
   - `start-application.sh` - Starts the application
   - `validate-service.sh` - Validates deployment success

### Post-Deployment Verification
After deployment, the application will be available at:
- Health endpoint: `http://your-ec2-ip:8080/api/documents/health`
- Application logs: `/var/log/docohpp/application.log`
- Process status: Check with `ps aux | grep doc.*ohpp`

### Verification Steps Completed
✅ **EC2 Instance Setup**: 
- Java 21 (Amazon Corretto) installed
- CodeDeploy agent running and configured
- X-Ray daemon installed and running as systemd service
- CloudWatch agent installed
- Application directories created: `/opt/docohpp` and `/var/log/docohpp`

✅ **CodeDeploy Infrastructure**:
- Application `DocOhpp` created
- Service role `codedeploy-service-role` configured with proper permissions
- Deployment group `DocOhpp-Production` targeting EC2 instances with required tags

✅ **Deployment Package Ready**:
- JAR file: `Doc_Ohpp-0.0.1-SNAPSHOT.jar`
- Configuration: `appspec.yml` 
- Deployment scripts: All scripts in `scripts/` directory

## CodePipeline Configuration

### Pipeline Overview
**Pipeline Name**: `DocOhpp-Pipeline`

**Pipeline Flow**: Source → Build → Deploy
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│             │    │             │    │             │    │             │
│   S3 Source │───▶│  CodeBuild  │───▶│ CodeDeploy  │───▶│EC2 Instance │
│   (GitHub)  │    │   (Maven)   │    │(Deployment) │    │   (App)     │
│             │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Pipeline Stages

#### Stage 1: Source
- **Action**: `SourceAction`
- **Provider**: AWS S3
- **Configuration**: 
  - S3 Bucket: `doc-ohpp-documents-bucket`
  - S3 Object Key: `source/source.zip`
  - Poll for Changes: Disabled (manual trigger)
- **Output Artifact**: `SourceOutput`

#### Stage 2: Build  
- **Action**: `BuildAction`
- **Provider**: AWS CodeBuild
- **Project**: `doc-ohpp-build`
- **Configuration**:
  - Environment: Amazon Linux 2, Java 21 (Corretto)
  - Build Spec: `buildspec.yml`
  - Compute: BUILD_GENERAL1_SMALL
- **Input Artifact**: `SourceOutput`
- **Output Artifact**: `BuildOutput`

#### Stage 3: Deploy
- **Action**: `DeployAction` 
- **Provider**: AWS CodeDeploy
- **Configuration**:
  - Application: `DocOhpp`
  - Deployment Group: `DocOhpp-Production`
  - Target: EC2 instances with tags `Application=DocOhpp`, `Environment=production`
- **Input Artifact**: `BuildOutput`

### Artifact Flow
1. **Source Artifact**: Complete source code from S3
2. **Build Artifact**: Compiled JAR file + deployment scripts + appspec.yml
3. **Deploy Artifact**: Deployed application on EC2 instance

### Pipeline Execution
- **Service Role**: `arn:aws:iam::{YOUR-ACCOUNT-ID}:role/codepipeline-service-role`
- **Artifact Store**: S3 bucket `doc-ohpp-documents-bucket`
- **Trigger Method**: Manual execution or S3 upload
- **Region**: eu-north-1

### Pipeline Verification
✅ **Infrastructure Setup Complete**:
- CodePipeline created with 3 stages
- CodeBuild project configured for Java 21
- CodeDeploy application and deployment group ready
- S3 artifact store configured
- IAM roles and permissions properly set

✅ **Pipeline Execution Test**:
- Source stage pulls from S3 successfully
- Build stage compiles Java application using Maven
- Deploy stage deploys to EC2 instances via CodeDeploy
- Complete artifact flow working: Source → Build → Deploy

### How to Trigger Pipeline

#### Manual Trigger:
```bash
# Start pipeline execution
aws codepipeline start-pipeline-execution --name DocOhpp-Pipeline

# Check pipeline status
aws codepipeline get-pipeline-state --name DocOhpp-Pipeline
```

#### Source Update Trigger:
```bash
# Create source package from your code
Compress-Archive -Path pom.xml, buildspec.yml, appspec.yml, src, scripts -DestinationPath source.zip -Force

# Upload to S3 to trigger pipeline
aws s3 cp source.zip s3://doc-ohpp-documents-bucket/source/source.zip
```

### Pipeline Monitoring
- **AWS Console**: Monitor pipeline execution in CodePipeline console
- **CloudWatch Logs**: Build logs available in CodeBuild project logs
- **CodeDeploy Console**: Deployment status and history
- **EC2 Instance**: Application health via `/api/documents/health` endpoint

### Pipeline Screenshots
*Note: Screenshots of successful pipeline runs can be found in the AWS CodePipeline console showing:*
- ✅ Source stage completion
- ✅ Build stage with successful Maven compilation
- ✅ Deploy stage with successful EC2 deployment
- ✅ Complete pipeline execution with all stages green

## Troubleshooting

### Common Issues
1. **CodeDeploy Agent Not Running**:
   ```bash
   sudo service codedeploy-agent start
   sudo chkconfig codedeploy-agent on
   ```

2. **Application Not Starting**:
   - Check logs: `tail -f /var/log/docohpp/application.log`
   - Verify Java: `java -version`
   - Check permissions: `ls -la /opt/docohpp/`

3. **Port 8080 Not Accessible**:
   - Check security group rules
   - Verify application is listening: `netstat -tlnp | grep :8080`

### Log Locations
- Application logs: `/var/log/docohpp/application.log`
- CodeDeploy logs: `/var/log/aws/codedeploy-agent/`
- X-Ray daemon logs: `sudo journalctl -u xray -f`

## Development

### Tech Stack
- **Backend**: Spring Boot 3.x, Java 21
- **AWS Services**: S3, DynamoDB, SQS, X-Ray, CloudWatch
- **Build Tool**: Maven
- **Deployment**: AWS CodeDeploy
- **CI/CD**: AWS CodeBuild + CodePipeline

### Project Structure
```
src/
├── main/java/com/example/Doc_Ohpp/
│   ├── config/          # Configuration classes
│   ├── controller/      # REST controllers
│   ├── model/          # Data models
│   └── service/        # Business logic
└── test/               # Unit and integration tests
```

## Security Considerations

- All AWS credentials managed through IAM roles
- No hardcoded secrets in application code
- S3 bucket policies restrict access
- Security groups limit network access
- X-Ray tracing for request monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `mvn test`
4. Build: `mvn clean package`
5. Submit a pull request

## License

This project is licensed under the MIT License.
