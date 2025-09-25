#!/bin/bash
# Deploy Doc_Ohpp using AWS CodeDeploy
# This script creates a deployment package and deploys it to your EC2 instance

set -e

# Configuration
APP_NAME="DocOhpp"
DEPLOYMENT_GROUP_NAME="DocOhpp-EC2-DeploymentGroup"
REGION="eu-north-1"
S3_BUCKET=""  # Will be prompted if not set
BUILD_DIR="target"
DEPLOYMENT_DESCRIPTION="Doc_Ohpp deployment $(date '+%Y-%m-%d %H:%M:%S')"

echo "Starting deployment process for Doc_Ohpp..."

# Function to check prerequisites
check_prerequisites() {
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    if [ ! -f "../../../$BUILD_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar" ]; then
        echo "ERROR: JAR file not found. Please build the application first using: ./mvnw clean package"
        exit 1
    fi

    echo "✓ Prerequisites check passed"
}

# Function to get or create S3 bucket for deployments
setup_s3_bucket() {
    if [ -z "$S3_BUCKET" ]; then
        read -p "Enter S3 bucket name for deployments (will be created if doesn't exist): " S3_BUCKET
    fi

    # Check if bucket exists
    if ! aws s3 ls "s3://$S3_BUCKET" &> /dev/null; then
        echo "Creating S3 bucket: $S3_BUCKET"
        aws s3 mb "s3://$S3_BUCKET" --region "$REGION"

        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$S3_BUCKET" \
            --versioning-configuration Status=Enabled

        echo "✓ Created S3 bucket: $S3_BUCKET"
    else
        echo "✓ Using existing S3 bucket: $S3_BUCKET"
    fi
}

# Function to create deployment package
create_deployment_package() {
    echo "Creating deployment package..."

    # Navigate to project root
    cd "$(dirname "$0")/../../.."

    # Create temporary directory for deployment package
    TEMP_DIR=$(mktemp -d)
    PACKAGE_NAME="docohpp-deployment-$(date +%Y%m%d-%H%M%S).zip"

    echo "Temporary directory: $TEMP_DIR"
    echo "Package name: $PACKAGE_NAME"

    # Copy application files
    mkdir -p "$TEMP_DIR"

    # Copy JAR file
    cp "$BUILD_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar" "$TEMP_DIR/"

    # Copy deployment scripts
    cp -r deployment/aws-codedeploy/scripts "$TEMP_DIR/"

    # Copy appspec.yml from deployment directory
    cp deployment/aws-codedeploy/appspec.yml "$TEMP_DIR/"

    # Make scripts executable
    chmod +x "$TEMP_DIR/scripts/"*.sh

    # Create deployment package
    cd "$TEMP_DIR"
    zip -r "../$PACKAGE_NAME" .

    # Move package to project root
    mv "../$PACKAGE_NAME" "$OLDPWD/"

    # Cleanup
    rm -rf "$TEMP_DIR"

    echo "✓ Created deployment package: $PACKAGE_NAME"
    echo "$PACKAGE_NAME"
}

# Function to upload package to S3
upload_to_s3() {
    local package_name=$1
    local s3_key="deployments/$package_name"

    echo "Uploading deployment package to S3..."

    aws s3 cp "$package_name" "s3://$S3_BUCKET/$s3_key"

    echo "✓ Uploaded to s3://$S3_BUCKET/$s3_key"
    echo "$s3_key"
}

# Function to create deployment
create_deployment() {
    local s3_key=$1
    local package_name=$2

    echo "Creating CodeDeploy deployment..."

    DEPLOYMENT_ID=$(aws deploy create-deployment \
        --application-name "$APP_NAME" \
        --deployment-group-name "$DEPLOYMENT_GROUP_NAME" \
        --description "$DEPLOYMENT_DESCRIPTION" \
        --s3-location bucket="$S3_BUCKET",key="$s3_key",bundleType=zip \
        --region "$REGION" \
        --query 'deploymentId' \
        --output text)

    echo "✓ Created deployment: $DEPLOYMENT_ID"
    echo "✓ Deployment package: $package_name"

    # Monitor deployment
    echo "Monitoring deployment progress..."
    aws deploy wait deployment-successful \
        --deployment-id "$DEPLOYMENT_ID" \
        --region "$REGION" \
        --cli-read-timeout 1200 \
        --cli-connect-timeout 60

    # Get deployment status
    DEPLOYMENT_STATUS=$(aws deploy get-deployment \
        --deployment-id "$DEPLOYMENT_ID" \
        --region "$REGION" \
        --query 'deploymentInfo.status' \
        --output text)

    if [ "$DEPLOYMENT_STATUS" = "Succeeded" ]; then
        echo "✅ Deployment completed successfully!"

        # Get instance information
        echo ""
        echo "Deployment Details:"
        aws deploy get-deployment \
            --deployment-id "$DEPLOYMENT_ID" \
            --region "$REGION" \
            --query 'deploymentInfo.{Status:status,CreatedTime:createTime,Description:description}' \
            --output table

        echo ""
        echo "Instance Status:"
        aws deploy list-deployment-instances \
            --deployment-id "$DEPLOYMENT_ID" \
            --region "$REGION" \
            --query 'instancesList' \
            --output table

    else
        echo "❌ Deployment failed with status: $DEPLOYMENT_STATUS"

        # Show deployment events for debugging
        echo "Deployment events:"
        aws deploy list-deployment-instances \
            --deployment-id "$DEPLOYMENT_ID" \
            --region "$REGION" \
            --output table

        exit 1
    fi

    # Cleanup local package
    rm -f "$package_name"

    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "Your application should now be running on your EC2 instance at port 8080"
}

# Function to show post-deployment information
show_post_deployment_info() {
    echo ""
    echo "📋 Post-Deployment Checklist:"
    echo "1. Check application logs: ssh to your instance and run 'tail -f /var/log/docohpp/application.log'"
    echo "2. Verify service is running: 'curl http://YOUR_INSTANCE_IP:8080/api/documents/health'"
    echo "3. Check process status: 'sudo systemctl status docohpp' or check PID file '/opt/docohpp/application.pid'"
    echo "4. Monitor CloudWatch logs in AWS Console"
    echo "5. Check X-Ray traces in AWS Console"
    echo ""
    echo "📁 Application deployed to: /opt/docohpp"
    echo "📝 Log files location: /var/log/docohpp/"
    echo "🔧 Service management: 'sudo systemctl [start|stop|restart|status] docohpp'"
}

# Main execution
main() {
    echo "🚀 Doc_Ohpp CodeDeploy Deployment Script"
    echo "========================================"

    check_prerequisites
    setup_s3_bucket

    PACKAGE_NAME=$(create_deployment_package)
    S3_KEY=$(upload_to_s3 "$PACKAGE_NAME")
    create_deployment "$S3_KEY" "$PACKAGE_NAME"

    show_post_deployment_info
}

# Show usage if help requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0 [S3_BUCKET_NAME]"
    echo ""
    echo "This script creates a deployment package and deploys Doc_Ohpp to EC2 using CodeDeploy."
    echo ""
    echo "Prerequisites:"
    echo "- AWS CLI installed and configured"
    echo "- Application built (./mvnw clean package)"
    echo "- CodeDeploy application and deployment group created"
    echo "- EC2 instance running with CodeDeploy agent installed"
    echo ""
    echo "Optional arguments:"
    echo "  S3_BUCKET_NAME  S3 bucket for storing deployment packages"
    echo ""
    exit 0
fi

# Set S3 bucket from argument if provided
if [ -n "$1" ]; then
    S3_BUCKET="$1"
fi

main "$@"
