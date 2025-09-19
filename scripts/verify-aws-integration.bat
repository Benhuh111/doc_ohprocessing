@echo off
echo === Doc_Ohpp AWS Integration Verification ===
echo Testing S3, DynamoDB, and SQS integration...
echo.

REM Test file upload via curl (assumes app is running on localhost:8080)
echo 1. Testing file upload...
echo test document content for verification > test-document.txt

REM Upload test file
curl -X POST -F "file=@test-document.txt" http://localhost:8080/api/documents/upload
echo.

REM Wait a moment for processing
timeout /t 3 /nobreak >nul

echo.
echo 2. Checking S3 bucket for uploaded file...
aws s3 ls s3://docohpp-documents-behu-20250827-001/ --region eu-north-1

echo.
echo 3. Checking DynamoDB table for document metadata...
aws dynamodb scan --table-name Doc_Ohpp --region eu-north-1 --query "Items[*].{DocumentId:documentId.S,Status:status.S,Timestamp:timestamp.S}"

echo.
echo 4. Checking SQS queue for messages...
for /f %%i in ('aws sqs get-queue-url --queue-name docoh-processing-queue --region eu-north-1 --query QueueUrl --output text') do set QUEUE_URL=%%i
aws sqs get-queue-attributes --queue-url "%QUEUE_URL%" --attribute-names ApproximateNumberOfMessages --region eu-north-1

echo.
echo Verification complete!

REM Cleanup
del test-document.txt
