@echo off
REM CodeDeploy Setup Script for Doc_Ohpp (Windows Version)
REM This script creates the CodeDeploy application and deployment group

setlocal EnableDelayedExpansion

REM Configuration
set APP_NAME=DocOhpp
set DEPLOYMENT_GROUP_NAME=DocOhpp-EC2-DeploymentGroup
set SERVICE_ROLE_NAME=DocOhpp-CodeDeploy-ServiceRole
set EC2_INSTANCE_ROLE_NAME=DocOhpp-EC2-InstanceRole
set REGION=eu-north-1

echo Setting up CodeDeploy for Doc_Ohpp...

REM Function to check if AWS CLI is configured
echo Checking AWS CLI configuration...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI is not configured. Please run 'aws configure' first.
    exit /b 1
)
echo ✓ AWS CLI is configured

REM Get Account ID
for /f "tokens=*" %%a in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%a
echo Account ID: %ACCOUNT_ID%

echo Creating CodeDeploy service role: %SERVICE_ROLE_NAME%
aws iam get-role --role-name "%SERVICE_ROLE_NAME%" >nul 2>&1
if errorlevel 1 (
    aws iam create-role --role-name "%SERVICE_ROLE_NAME%" --assume-role-policy-document file://..\iam-policies\codedeploy-trust-policy.json --region "%REGION%"
    echo ✓ Created IAM role: %SERVICE_ROLE_NAME%
) else (
    echo ✓ IAM role already exists: %SERVICE_ROLE_NAME%
)

REM Create and attach CodeDeploy service policy
set CODEDEPLOY_POLICY_NAME=%SERVICE_ROLE_NAME%-Policy
set CODEDEPLOY_POLICY_ARN=arn:aws:iam::%ACCOUNT_ID%:policy/%CODEDEPLOY_POLICY_NAME%

aws iam get-policy --policy-arn "%CODEDEPLOY_POLICY_ARN%" >nul 2>&1
if errorlevel 1 (
    aws iam create-policy --policy-name "%CODEDEPLOY_POLICY_NAME%" --policy-document file://..\iam-policies\codedeploy-service-policy.json --region "%REGION%"
    echo ✓ Created IAM policy: %CODEDEPLOY_POLICY_NAME%
) else (
    echo ✓ IAM policy already exists: %CODEDEPLOY_POLICY_NAME%
)

aws iam attach-role-policy --role-name "%SERVICE_ROLE_NAME%" --policy-arn "%CODEDEPLOY_POLICY_ARN%" --region "%REGION%"
echo ✓ Attached policy to role: %SERVICE_ROLE_NAME%

echo Creating EC2 instance role: %EC2_INSTANCE_ROLE_NAME%
aws iam get-role --role-name "%EC2_INSTANCE_ROLE_NAME%" >nul 2>&1
if errorlevel 1 (
    aws iam create-role --role-name "%EC2_INSTANCE_ROLE_NAME%" --assume-role-policy-document file://..\iam-policies\ec2-trust-policy.json --region "%REGION%"
    echo ✓ Created IAM role: %EC2_INSTANCE_ROLE_NAME%
) else (
    echo ✓ IAM role already exists: %EC2_INSTANCE_ROLE_NAME%
)

REM Attach AWS managed policies to EC2 role
echo Attaching AWS managed policies to EC2 role...
aws iam attach-role-policy --role-name "%EC2_INSTANCE_ROLE_NAME%" --policy-arn "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
aws iam attach-role-policy --role-name "%EC2_INSTANCE_ROLE_NAME%" --policy-arn "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
aws iam attach-role-policy --role-name "%EC2_INSTANCE_ROLE_NAME%" --policy-arn "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
echo ✓ Attached AWS managed policies

REM Create and attach custom policies for EC2 role
echo Creating and attaching custom policies...
for %%p in (docohpp-s3-policy.json docohpp-dynamodb-policy.json docohpp-sqs-policy.json docohpp-cloudwatch-policy.json docohpp-xray-policy.json) do (
    if exist "..\iam-policies\%%p" (
        set POLICY_FILE=%%p
        set POLICY_NAME=DocOhpp-!POLICY_FILE:~8,-5!
        set CUSTOM_POLICY_ARN=arn:aws:iam::%ACCOUNT_ID%:policy/!POLICY_NAME!

        aws iam get-policy --policy-arn "!CUSTOM_POLICY_ARN!" >nul 2>&1
        if errorlevel 1 (
            aws iam create-policy --policy-name "!POLICY_NAME!" --policy-document file://..\iam-policies\%%p
            echo ✓ Created policy: !POLICY_NAME!
        ) else (
            echo ✓ Policy already exists: !POLICY_NAME!
        )

        aws iam attach-role-policy --role-name "%EC2_INSTANCE_ROLE_NAME%" --policy-arn "!CUSTOM_POLICY_ARN!"
    )
)

REM Create instance profile
set INSTANCE_PROFILE_NAME=%EC2_INSTANCE_ROLE_NAME%-InstanceProfile
echo Creating instance profile: %INSTANCE_PROFILE_NAME%

aws iam get-instance-profile --instance-profile-name "%INSTANCE_PROFILE_NAME%" >nul 2>&1
if errorlevel 1 (
    aws iam create-instance-profile --instance-profile-name "%INSTANCE_PROFILE_NAME%" --region "%REGION%"
    echo ✓ Created instance profile: %INSTANCE_PROFILE_NAME%
) else (
    echo ✓ Instance profile already exists: %INSTANCE_PROFILE_NAME%
)

REM Add role to instance profile
aws iam add-role-to-instance-profile --instance-profile-name "%INSTANCE_PROFILE_NAME%" --role-name "%EC2_INSTANCE_ROLE_NAME%" --region "%REGION%" >nul 2>&1
echo ✓ Added role to instance profile: %INSTANCE_PROFILE_NAME%

REM Create CodeDeploy application
echo Creating CodeDeploy application: %APP_NAME%
aws deploy get-application --application-name "%APP_NAME%" --region "%REGION%" >nul 2>&1
if errorlevel 1 (
    aws deploy create-application --application-name "%APP_NAME%" --compute-platform EC2 --region "%REGION%"
    echo ✓ Created CodeDeploy application: %APP_NAME%
) else (
    echo ✓ CodeDeploy application already exists: %APP_NAME%
)

REM Create deployment group
echo Creating deployment group: %DEPLOYMENT_GROUP_NAME%
set SERVICE_ROLE_ARN=arn:aws:iam::%ACCOUNT_ID%:role/%SERVICE_ROLE_NAME%

aws deploy get-deployment-group --application-name "%APP_NAME%" --deployment-group-name "%DEPLOYMENT_GROUP_NAME%" --region "%REGION%" >nul 2>&1
if errorlevel 1 (
    aws deploy create-deployment-group --application-name "%APP_NAME%" --deployment-group-name "%DEPLOYMENT_GROUP_NAME%" --service-role-arn "%SERVICE_ROLE_ARN%" --ec2-tag-filters Key=Name,Value=DocOhpp-Instance,Type=KEY_AND_VALUE --deployment-style deploymentType=IN_PLACE --region "%REGION%"
    echo ✓ Created deployment group: %DEPLOYMENT_GROUP_NAME%
) else (
    echo ✓ Deployment group already exists: %DEPLOYMENT_GROUP_NAME%
)

echo.
echo ✅ CodeDeploy setup completed successfully!
echo.
echo Next steps:
echo 1. Launch an EC2 instance (Amazon Linux 2) with the instance profile: %INSTANCE_PROFILE_NAME%
echo 2. Tag your EC2 instance with: Name=DocOhpp-Instance
echo 3. Install CodeDeploy agent on the instance
echo 4. Configure security group to allow port 8080
echo 5. Test deployment using the created application: %APP_NAME%
echo.
echo Instance profile ARN: arn:aws:iam::%ACCOUNT_ID%:instance-profile/%INSTANCE_PROFILE_NAME%
echo CodeDeploy application: %APP_NAME%
echo Deployment group: %DEPLOYMENT_GROUP_NAME%

pause
