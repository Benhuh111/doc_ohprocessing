#!/bin/bash
# CodeDeploy Setup Script for Doc_Ohpp
# This script creates the CodeDeploy application and deployment group

set -e

# Configuration
APP_NAME="DocOhpp"
DEPLOYMENT_GROUP_NAME="DocOhpp-EC2-DeploymentGroup"
SERVICE_ROLE_NAME="DocOhpp-CodeDeploy-ServiceRole"
EC2_INSTANCE_ROLE_NAME="DocOhpp-EC2-InstanceRole"
REGION="eu-north-1"

echo "Setting up CodeDeploy for Doc_Ohpp..."

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "ERROR: AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    echo "✓ AWS CLI is configured"
}

# Function to create IAM role
create_iam_role() {
    local role_name=$1
    local trust_policy_file=$2
    local policy_file=$3

    echo "Creating IAM role: $role_name"

    # Create role if it doesn't exist
    if ! aws iam get-role --role-name "$role_name" &> /dev/null; then
        aws iam create-role \
            --role-name "$role_name" \
            --assume-role-policy-document "file://$trust_policy_file" \
            --region "$REGION"
        echo "✓ Created IAM role: $role_name"
    else
        echo "✓ IAM role already exists: $role_name"
    fi

    # Attach policy
    if [ -n "$policy_file" ]; then
        local policy_name="${role_name}-Policy"

        # Create policy if it doesn't exist
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${policy_name}"

        if ! aws iam get-policy --policy-arn "$POLICY_ARN" &> /dev/null; then
            aws iam create-policy \
                --policy-name "$policy_name" \
                --policy-document "file://$policy_file" \
                --region "$REGION"
            echo "✓ Created IAM policy: $policy_name"
        else
            echo "✓ IAM policy already exists: $policy_name"
        fi

        # Attach policy to role
        aws iam attach-role-policy \
            --role-name "$role_name" \
            --policy-arn "$POLICY_ARN" \
            --region "$REGION"
        echo "✓ Attached policy to role: $role_name"
    fi
}

# Function to create instance profile
create_instance_profile() {
    local role_name=$1
    local profile_name="${role_name}-InstanceProfile"

    echo "Creating instance profile: $profile_name"

    # Create instance profile if it doesn't exist
    if ! aws iam get-instance-profile --instance-profile-name "$profile_name" &> /dev/null; then
        aws iam create-instance-profile \
            --instance-profile-name "$profile_name" \
            --region "$REGION"
        echo "✓ Created instance profile: $profile_name"
    else
        echo "✓ Instance profile already exists: $profile_name"
    fi

    # Add role to instance profile
    if ! aws iam get-instance-profile --instance-profile-name "$profile_name" --query 'InstanceProfile.Roles[?RoleName==`'$role_name'`]' --output text | grep -q "$role_name"; then
        aws iam add-role-to-instance-profile \
            --instance-profile-name "$profile_name" \
            --role-name "$role_name" \
            --region "$REGION"
        echo "✓ Added role to instance profile: $profile_name"
    else
        echo "✓ Role already in instance profile: $profile_name"
    fi
}

# Function to create CodeDeploy application
create_codedeploy_application() {
    echo "Creating CodeDeploy application: $APP_NAME"

    if ! aws deploy get-application --application-name "$APP_NAME" --region "$REGION" &> /dev/null; then
        aws deploy create-application \
            --application-name "$APP_NAME" \
            --compute-platform EC2 \
            --region "$REGION"
        echo "✓ Created CodeDeploy application: $APP_NAME"
    else
        echo "✓ CodeDeploy application already exists: $APP_NAME"
    fi
}

# Function to create deployment group
create_deployment_group() {
    echo "Creating deployment group: $DEPLOYMENT_GROUP_NAME"

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    SERVICE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${SERVICE_ROLE_NAME}"

    if ! aws deploy get-deployment-group \
        --application-name "$APP_NAME" \
        --deployment-group-name "$DEPLOYMENT_GROUP_NAME" \
        --region "$REGION" &> /dev/null; then

        aws deploy create-deployment-group \
            --application-name "$APP_NAME" \
            --deployment-group-name "$DEPLOYMENT_GROUP_NAME" \
            --service-role-arn "$SERVICE_ROLE_ARN" \
            --ec2-tag-filters Key=Name,Value=DocOhpp-Instance,Type=KEY_AND_VALUE \
            --deployment-style deploymentType=IN_PLACE \
            --region "$REGION"
        echo "✓ Created deployment group: $DEPLOYMENT_GROUP_NAME"
    else
        echo "✓ Deployment group already exists: $DEPLOYMENT_GROUP_NAME"
    fi
}

# Main execution
main() {
    echo "Starting CodeDeploy setup for Doc_Ohpp..."

    check_aws_cli

    # Navigate to the deployment directory
    cd "$(dirname "$0")"

    # Create CodeDeploy service role
    create_iam_role "$SERVICE_ROLE_NAME" "../iam-policies/codedeploy-trust-policy.json" "../iam-policies/codedeploy-service-policy.json"

    # Create EC2 instance role (combine all required policies)
    create_iam_role "$EC2_INSTANCE_ROLE_NAME" "../iam-policies/ec2-trust-policy.json"

    # Attach additional policies to EC2 role
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    EC2_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${EC2_INSTANCE_ROLE_NAME}"

    # Attach AWS managed policies
    aws iam attach-role-policy --role-name "$EC2_INSTANCE_ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    aws iam attach-role-policy --role-name "$EC2_INSTANCE_ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
    aws iam attach-role-policy --role-name "$EC2_INSTANCE_ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"

    # Attach custom policies
    for policy_file in "../iam-policies/docohpp-s3-policy.json" \
                       "../iam-policies/docohpp-dynamodb-policy.json" \
                       "../iam-policies/docohpp-sqs-policy.json"; do
        if [ -f "$policy_file" ]; then
            policy_name=$(basename "$policy_file" .json)
            policy_name="DocOhpp-${policy_name#docohpp-}"
            POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${policy_name}"

            if ! aws iam get-policy --policy-arn "$POLICY_ARN" &> /dev/null; then
                aws iam create-policy --policy-name "$policy_name" --policy-document "file://$policy_file"
            fi
            aws iam attach-role-policy --role-name "$EC2_INSTANCE_ROLE_NAME" --policy-arn "$POLICY_ARN"
        fi
    done

    # Create instance profile
    create_instance_profile "$EC2_INSTANCE_ROLE_NAME"

    # Create CodeDeploy application
    create_codedeploy_application

    # Create deployment group
    create_deployment_group

    echo ""
    echo "✅ CodeDeploy setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Launch an EC2 instance (Amazon Linux 2) with the instance profile: ${EC2_INSTANCE_ROLE_NAME}-InstanceProfile"
    echo "2. Tag your EC2 instance with: Name=DocOhpp-Instance"
    echo "3. Install CodeDeploy agent on the instance"
    echo "4. Configure security group to allow port 8080"
    echo "5. Test deployment using the created application: $APP_NAME"
    echo ""
    echo "Instance profile ARN: arn:aws:iam::${ACCOUNT_ID}:instance-profile/${EC2_INSTANCE_ROLE_NAME}-InstanceProfile"
    echo "CodeDeploy application: $APP_NAME"
    echo "Deployment group: $DEPLOYMENT_GROUP_NAME"
}

main "$@"
