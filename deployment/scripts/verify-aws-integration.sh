#!/bin/bash
# Verification script to test AWS integration

echo "=== Doc_Ohpp AWS Integration Verification ==="
echo "Testing S3, DynamoDB, and SQS integration..."
echo ""

# Test file upload via curl (assumes app is running on localhost:8080)
echo "1. Testing file upload..."
echo "test document content for verification" > test-document.txt

# Upload test file
curl -X POST -F "file=@test-document.txt" http://localhost:8080/api/documents/upload
echo ""

# Wait a moment for processing
sleep 2

echo ""
echo "2. Checking S3 bucket for uploaded file..."
aws s3 ls s3://docohpp-documents-behu-20250827-001/ --region eu-north-1

echo ""
echo "3. Checking DynamoDB table for document metadata..."
aws dynamodb scan --table-name Doc_Ohpp --region eu-north-1 --query 'Items[*].{DocumentId:documentId.S,Status:status.S,Timestamp:timestamp.S}'

echo ""
echo "4. Checking SQS queue for messages..."
aws sqs get-queue-attributes --queue-url "$(aws sqs get-queue-url --queue-name docoh-processing-queue --region eu-north-1 --query 'QueueUrl' --output text)" --attribute-names ApproximateNumberOfMessages --region eu-north-1

echo ""
echo "Verification complete!"

# Cleanup
rm -f test-document.txt
