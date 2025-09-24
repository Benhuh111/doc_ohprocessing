@echo off
echo Updating IAM policy for EC2 instance role...

REM Update the S3 policy attached to the EC2 instance role
aws iam put-role-policy ^
    --role-name DocOhpp-EC2-InstanceRole ^
    --policy-name DocOhpp-S3-Policy ^
    --policy-document file://iam-policies/docohpp-s3-policy.json

if %ERRORLEVEL% EQU 0 (
    echo S3 policy updated successfully!
    echo The EC2 instances should now have access to CodePipeline artifacts.
    echo You can retry your deployment now.
) else (
    echo Failed to update S3 policy. Please check your AWS credentials and permissions.
)

pause
