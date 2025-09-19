@echo off
echo === IAM Policy Verification for Doc_Ohpp ===
echo Testing IAM permissions using AWS Policy Simulator...
echo.

echo 1. Testing EC2 Instance Role permissions...
echo Testing S3 permissions:
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-EC2-InstanceRole --action-names s3:PutObject s3:GetObject s3:DeleteObject --resource-arns arn:aws:s3:::docohpp-documents-behu-20250827-001/test-file.txt

echo.
echo Testing DynamoDB permissions:
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-EC2-InstanceRole --action-names dynamodb:PutItem dynamodb:GetItem dynamodb:UpdateItem dynamodb:DeleteItem dynamodb:Scan --resource-arns arn:aws:dynamodb:eu-north-1:535002890586:table/Doc_Ohpp

echo.
echo Testing SQS permissions:
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-EC2-InstanceRole --action-names sqs:SendMessage sqs:GetQueueAttributes --resource-arns arn:aws:sqs:eu-north-1:535002890586:docoh-processing-queue

echo.
echo Testing X-Ray permissions:
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-EC2-InstanceRole --action-names xray:PutTraceSegments xray:PutTelemetryRecords --resource-arns "*"

echo.
echo 2. Testing CodeBuild Service Role permissions...
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-CodeBuild-ServiceRole --action-names logs:CreateLogGroup logs:CreateLogStream logs:PutLogEvents --resource-arns arn:aws:logs:eu-north-1:535002890586:log-group:/aws/codebuild/docohpp-build

echo.
echo 3. Testing CodeDeploy Service Role permissions...
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::535002890586:role/DocOhpp-CodeDeploy-ServiceRole --action-names ec2:DescribeInstances autoscaling:DescribeAutoScalingGroups --resource-arns "*"

echo.
echo Verification complete!
