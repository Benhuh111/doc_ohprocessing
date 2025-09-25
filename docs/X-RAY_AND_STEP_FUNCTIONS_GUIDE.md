
## Console Links and Monitoring

### X-Ray Console
- **Service Map**: Monitor service topology and performance
- **Traces**: View individual request traces with timing
- **Analytics**: Analyze patterns and performance trends

### Step Functions Console
- **State Machines**: View and manage workflows
- **Executions**: Monitor workflow executions
- **Definition**: View and edit workflow definitions

### Next Steps

1. **Deploy and Test**: Run the deployment scripts and verify functionality
2. **Monitor**: Check both X-Ray and Step Functions consoles
3. **Document**: Take screenshots of successful traces and executions
4. **Integrate**: Consider integrating Step Functions with your document processing workflow
5. **Optimize**: Fine-tune X-Ray sampling and Step Functions for production use
# AWS X-Ray and Step Functions Implementation Guide

## AWS X-Ray Tracing

### Overview
Your Doc_Ohpp application now includes comprehensive X-Ray tracing with custom segments, annotations, and metadata for detailed performance monitoring and debugging.

### Implementation Details

#### 1. X-Ray Configuration
- **Service Name**: `DocOh-Service` (configured in `application.properties`)
- **Plugins**: EC2Plugin and ECSPlugin for environment detection
- **Sampling**: DefaultSamplingStrategy for production, NoSamplingStrategy for local development

#### 2. Enhanced Tracing Features

**Custom Segments Added:**
- `document-upload`: Tracks the entire document upload process
- `s3-upload`: Specific S3 upload operations
- `document-processing`: Async document processing workflow
- `health-check`: Health endpoint monitoring

**Annotations for Filtering:**
- `operation`: Type of operation (upload, health, processing)
- `fileName`: Document filename
- `fileSize`: File size for performance correlation
- `service`: AWS service being used (s3, dynamodb, sqs)
- `bucket`: S3 bucket name
- `error`: Error type when failures occur

**Metadata for Detailed Analysis:**
- Upload details (original filename, content type)
- Processing results and timing
- Health check statistics
- Error messages and stack traces

#### 3. Verification Steps

**On EC2 Instance:**
```bash
# Check X-Ray daemon status
sudo systemctl status xray

# View X-Ray daemon logs
sudo journalctl -u xray -f

# Ensure daemon is running
sudo systemctl start xray
sudo systemctl enable xray
```

**Required IAM Permissions:**
Your EC2 instance role must include:
- `xray:PutTraceSegments`
- `xray:PutTelemetryRecords`
- `xray:GetServiceGraph`
- `xray:GetTraceSummaries`

**Testing X-Ray Traces:**
1. Make API calls to your application:
   ```bash
   curl http://YOUR_INSTANCE_IP:8080/api/documents/health
   curl -X POST -F "file=@test.pdf" http://YOUR_INSTANCE_IP:8080/api/documents/upload
   ```

2. Wait 1-2 minutes for traces to appear in the X-Ray console

3. Check the X-Ray console:
   - **Service Map**: https://eu-north-1.console.aws.amazon.com/xray/home?region=eu-north-1#/service-map
   - **Traces**: https://eu-north-1.console.aws.amazon.com/xray/home?region=eu-north-1#/traces

#### 4. Expected X-Ray Results

**Service Map View:**
- Shows `DocOh-Service` as the main service
- Connected to downstream services (S3, DynamoDB, SQS)
- Response time and error rate metrics

**Trace Details:**
- Root segment for HTTP requests
- Subsegments for each service call
- Custom subsegments for business logic
- Annotations visible in trace filter
- Metadata available in trace details

---

## Step Functions Implementation

### Overview
Two Step Functions workflows have been created to demonstrate document processing orchestration with validation, parallel processing, and error handling.

### Workflow 1: Basic Document Processing

**File**: `deployment/step-functions/document-processing-workflow.json`

**Flow**:
1. **ValidateInput** (Pass State): Validates document metadata
2. **CheckFileSize** (Choice State): Validates file size < 10MB
3. **FileTooLarge** (Fail State): Handles oversized files
4. **ProcessDocument** (Task/Pass State): Simulates document processing
5. **NotifyCompletion** (Pass State): Sends completion notification

**Features**:
- File size validation with failure handling
- Simulated document processing with metadata extraction
- Structured output with validation and processing results

### Workflow 2: Advanced Document Processing

**File**: `deployment/step-functions/advanced-document-workflow.json`

**Flow**:
1. **ValidateAndPreprocess** (Parallel State): 
   - Validates input in parallel with metadata preprocessing
2. **ProcessingDecision** (Choice State): Routes based on content type
3. **Type-specific Processing** (Pass States):
   - **ImageProcessing**: OCR simulation
   - **PDFProcessing**: PDF text extraction
   - **TextProcessing**: Text analysis
   - **GenericProcessing**: Fallback processing
4. **FinalProcessing** (Pass State): Consolidates results

**Features**:
- Parallel validation and preprocessing
- Content-type-based routing
- Different processing logic for images, PDFs, and text files
- Comprehensive result consolidation

### Deployment and Testing

#### 1. Deploy Step Functions
```cmd
cd deployment\step-functions
deploy-step-functions.bat
```

This script:
- Creates necessary IAM roles
- Deploys both state machines
- Runs initial test executions
- Provides console links for monitoring

#### 2. Test Different Scenarios
```cmd
test-workflows.bat
```

**Test Cases Include**:
- PDF document processing
- Image OCR processing
- Large file validation (failure scenario)
- Different content types

#### 3. State Machine ARNs
- **Basic**: `arn:aws:states:eu-north-1:ACCOUNT_ID:stateMachine:DocOhpp-Basic-Processing`
- **Advanced**: `arn:aws:states:eu-north-1:ACCOUNT_ID:stateMachine:DocOhpp-Advanced-Processing`

### Expected Results

#### Console Views
1. **Workflow Diagrams**: Visual representation of state machines
2. **Execution History**: List of all executions with status
3. **Execution Details**: Step-by-step execution with input/output
4. **CloudWatch Integration**: Metrics and logs for monitoring

#### Sample Execution Results

**Successful PDF Processing** (Basic Workflow):
```json
{
  "documentId": "test-pdf-001",
  "fileName": "business-report.pdf",
  "status": "WORKFLOW_COMPLETED",
  "validation": {
    "validationResult": "PASSED",
    "validationTimestamp": "2025-09-25T10:30:00.000Z"
  },
  "processing": {
    "status": "COMPLETED",
    "processingTime": 2500,
    "extractedText": "Sample extracted text content..."
  }
}
```

**Image OCR Processing** (Advanced Workflow):
```json
{
  "documentId": "test-img-001",
  "fileName": "scanned-document.jpg",
  "processingType": "OCR",
  "result": {
    "status": "COMPLETED",
    "confidence": 0.92,
    "extractedText": "Sample OCR extracted text from image",
    "processingTime": 3500
  }
}
```

### Integration with Your Application

The Step Functions workflows can be integrated with your Spring Boot application by:

1. Adding Step Functions SDK to your dependencies
2. Creating a Step Functions service to start executions
3. Triggering workflows from document upload endpoints
4. Monitoring execution status and handling results

---

