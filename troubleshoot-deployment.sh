#!/bin/bash
# Comprehensive deployment troubleshooting script

echo "=== DocOhpp Deployment Troubleshooting ==="
echo "Date: $(date)"
echo ""

# Check EC2 instance health
echo "1. Checking EC2 instance health..."
aws ec2 describe-instances --filters "Name=tag:Application,Values=DocOhpp" \
    --query "Reservations[*].Instances[*].{InstanceId:InstanceId,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}" \
    --output table
echo ""

# Check latest deployment details
echo "2. Getting latest deployment details..."
LATEST_DEPLOYMENT=$(aws deploy list-deployments --application-name DocOhpp-Application --deployment-group-name DocOhpp-DeploymentGroup --max-items 1 --query "deployments[0]" --output text 2>/dev/null)
if [ ! -z "$LATEST_DEPLOYMENT" ]; then
    echo "Latest deployment ID: $LATEST_DEPLOYMENT"
    aws deploy get-deployment --deployment-id "$LATEST_DEPLOYMENT" --query "deploymentInfo.{status:status,errorCode:errorInformation.code,errorMessage:errorInformation.message}" --output table
else
    echo "No deployments found"
fi
echo ""

# Check deployment group configuration
echo "3. Checking deployment group configuration..."
aws deploy get-deployment-group --application-name DocOhpp-Application --deployment-group-name DocOhpp-DeploymentGroup \
    --query "deploymentGroupInfo.{serviceRoleArn:serviceRoleArn,ec2TagFilters:ec2TagFilters}" --output table
echo ""

# Check if CodeDeploy agent is installed and running on the instance
echo "4. Checking CodeDeploy agent status..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Application,Values=DocOhpp" --query "Reservations[0].Instances[0].InstanceId" --output text 2>/dev/null)
if [ ! -z "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    echo "Instance ID: $INSTANCE_ID"
    echo "Attempting to check CodeDeploy agent status on instance..."
    # Note: This would require SSM or direct SSH access to check agent status
    echo "Instance found but direct agent status check requires SSM/SSH access"
else
    echo "No instance found with Application:DocOhpp tag"
fi
echo ""

# Check recent deployment instance failures
echo "5. Checking recent deployment failures..."
if [ ! -z "$LATEST_DEPLOYMENT" ]; then
    aws deploy list-deployment-instances --deployment-id "$LATEST_DEPLOYMENT" --query "instancesList[*].{instanceId:instanceId,status:status}" --output table

    # Get specific failure details for the instance
    if [ ! -z "$INSTANCE_ID" ]; then
        echo "Getting lifecycle event failures for instance $INSTANCE_ID..."
        aws deploy get-deployment-instance --deployment-id "$LATEST_DEPLOYMENT" --instance-id "$INSTANCE_ID" \
            --query "instanceSummary.lifecycleEvents[?status=='Failed'].{event:lifecycleEventName,error:diagnostics.errorCode,message:diagnostics.message}" --output table
    fi
fi
echo ""

# Check if there are multiple failed deployments
echo "6. Checking deployment history..."
aws deploy list-deployments --application-name DocOhpp-Application --deployment-group-name DocOhpp-DeploymentGroup --max-items 5 \
    --query "deployments" --output table
echo ""

echo "=== Troubleshooting Complete ==="
echo "Next steps based on findings above:"
echo "1. Verify EC2 instance is running and healthy"
echo "2. Check CodeDeploy agent is installed and running"
echo "3. Verify deployment scripts exist in the deployment package"
echo "4. Check IAM permissions for both EC2 instance role and CodeDeploy service role"
