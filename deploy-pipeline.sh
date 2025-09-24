#!/bin/bash
# Deploy Script for Doc_Ohpp CodePipeline
echo "=== Doc_Ohpp Pipeline Deployment Script ==="

# Configuration
S3_BUCKET="doc-ohpp-documents-bucket"
SOURCE_KEY="source/source.zip"
REGION="eu-north-1"

# Create deployment package
echo "Creating source package..."
rm -f source.zip

# Package the source code with all necessary files
zip -r source.zip \
    src/ \
    scripts/ \
    pom.xml \
    buildspec.yml \
    appspec.yml \
    -x "target/*" "*.git*" "*.idea*" "*.iml" "node_modules/*"

echo "Source package created: source.zip"

# Upload to S3 to trigger the pipeline
echo "Uploading to S3: s3://$S3_BUCKET/$SOURCE_KEY"
aws s3 cp source.zip s3://$S3_BUCKET/$SOURCE_KEY --region $REGION

if [ $? -eq 0 ]; then
    echo "✓ Successfully uploaded source package to S3"
    echo "✓ CodePipeline should automatically trigger now"
    echo ""
    echo "Monitor your pipeline at:"
    echo "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/DocOhpp-Pipeline/view"
else
    echo "✗ Failed to upload to S3. Check your AWS credentials and permissions."
    exit 1
fi

echo ""
echo "=== Deployment Summary ==="
echo "• Source package: source.zip"
echo "• S3 Location: s3://$S3_BUCKET/$SOURCE_KEY"
echo "• Region: $REGION"
echo "• Pipeline: DocOhpp-Pipeline"
echo ""
echo "Your pipeline should now execute all three stages:"
echo "1. Source: Download from S3"
echo "2. Build: Compile with Maven using fixed buildspec.yml"
echo "3. Deploy: Deploy to EC2 using CodeDeploy with corrected appspec.yml"
