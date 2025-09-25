@echo off
REM Deploy Doc_Ohpp using AWS CodeDeploy (Windows Version)
REM This script creates a deployment package and deploys it to your EC2 instance

setlocal EnableDelayedExpansion

REM Configuration
set APP_NAME=DocOhpp
set DEPLOYMENT_GROUP_NAME=DocOhpp-EC2-DeploymentGroup
set REGION=eu-north-1
set BUILD_DIR=..\..\target
set DEPLOYMENT_DESCRIPTION=Doc_Ohpp deployment %date% %time%

echo Starting deployment process for Doc_Ohpp...

REM Function to check prerequisites
echo Checking prerequisites...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI is not configured. Please run 'aws configure' first.
    exit /b 1
)

if not exist "%BUILD_DIR%\Doc_Ohpp-0.0.1-SNAPSHOT.jar" (
    echo ERROR: JAR file not found. Please build the application first using: .\mvnw clean package
    exit /b 1
)

echo ✓ Prerequisites check passed

REM Get or create S3 bucket for deployments
if "%~1"=="" (
    set /p S3_BUCKET="Enter S3 bucket name for deployments (will be created if doesn't exist): "
) else (
    set S3_BUCKET=%~1
)

echo Using S3 bucket: %S3_BUCKET%

REM Check if bucket exists
aws s3 ls s3://%S3_BUCKET% >nul 2>&1
if errorlevel 1 (
    echo Creating S3 bucket: %S3_BUCKET%
    aws s3 mb s3://%S3_BUCKET% --region %REGION%
    aws s3api put-bucket-versioning --bucket %S3_BUCKET% --versioning-configuration Status=Enabled
    echo ✓ Created S3 bucket: %S3_BUCKET%
) else (
    echo ✓ Using existing S3 bucket: %S3_BUCKET%
)

REM Create deployment package
echo Creating deployment package...
set PACKAGE_NAME=docohpp-deployment-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%.zip
set PACKAGE_NAME=%PACKAGE_NAME: =0%

REM Create temporary directory for deployment package
set TEMP_DIR=%TEMP%\docohpp-deploy-%RANDOM%
mkdir "%TEMP_DIR%"

echo Temporary directory: %TEMP_DIR%
echo Package name: %PACKAGE_NAME%

REM Copy application files
copy "%BUILD_DIR%\Doc_Ohpp-0.0.1-SNAPSHOT.jar" "%TEMP_DIR%\"
xcopy /E /I scripts "%TEMP_DIR%\scripts\"
copy appspec.yml "%TEMP_DIR%\"

REM Create deployment package
cd "%TEMP_DIR%"
powershell -Command "Compress-Archive -Path * -DestinationPath '%CD%\..\%PACKAGE_NAME%'"
cd ..
move "%PACKAGE_NAME%" "%~dp0..\..\%PACKAGE_NAME%"

REM Cleanup temp directory
rmdir /S /Q "%TEMP_DIR%"

cd "%~dp0..\.."
echo ✓ Created deployment package: %PACKAGE_NAME%

REM Upload package to S3
echo Uploading deployment package to S3...
set S3_KEY=deployments/%PACKAGE_NAME%
aws s3 cp "%PACKAGE_NAME%" "s3://%S3_BUCKET%/%S3_KEY%"
echo ✓ Uploaded to s3://%S3_BUCKET%/%S3_KEY%

REM Create deployment
echo Creating CodeDeploy deployment...
aws deploy create-deployment --application-name "%APP_NAME%" --deployment-group-name "%DEPLOYMENT_GROUP_NAME%" --description "%DEPLOYMENT_DESCRIPTION%" --s3-location bucket=%S3_BUCKET%,key=%S3_KEY%,bundleType=zip --region "%REGION%" --query deploymentId --output text > temp_deployment_id.txt
set /p DEPLOYMENT_ID=<temp_deployment_id.txt
del temp_deployment_id.txt

echo ✓ Created deployment: %DEPLOYMENT_ID%
echo ✓ Deployment package: %PACKAGE_NAME%

REM Monitor deployment
echo Monitoring deployment progress...
echo This may take several minutes...

aws deploy wait deployment-successful --deployment-id "%DEPLOYMENT_ID%" --region "%REGION%"

if errorlevel 1 (
    echo ❌ Deployment failed!
    echo Checking deployment status...
    aws deploy get-deployment --deployment-id "%DEPLOYMENT_ID%" --region "%REGION%" --query "deploymentInfo.{Status:status,ErrorMessage:errorInformation.message}" --output table
    echo.
    echo Instance Status:
    aws deploy list-deployment-instances --deployment-id "%DEPLOYMENT_ID%" --region "%REGION%" --output table
    exit /b 1
) else (
    echo ✅ Deployment completed successfully!

    REM Show deployment details
    echo.
    echo Deployment Details:
    aws deploy get-deployment --deployment-id "%DEPLOYMENT_ID%" --region "%REGION%" --query "deploymentInfo.{Status:status,CreatedTime:createTime,Description:description}" --output table

    echo.
    echo Instance Status:
    aws deploy list-deployment-instances --deployment-id "%DEPLOYMENT_ID%" --region "%REGION%" --output table
)

REM Cleanup local package
del "%PACKAGE_NAME%"

echo.
echo 🎉 Deployment completed successfully!
echo Your application should now be running on your EC2 instance at port 8080
echo.
echo 📋 Post-Deployment Checklist:
echo 1. Check application logs: ssh to your instance and run 'tail -f /var/log/docohpp/application.log'
echo 2. Verify service is running: 'curl http://YOUR_INSTANCE_IP:8080/api/documents/health'
echo 3. Check process status: 'sudo systemctl status docohpp' or check PID file '/opt/docohpp/application.pid'
echo 4. Monitor CloudWatch logs in AWS Console
echo 5. Check X-Ray traces in AWS Console
echo.
echo 📁 Application deployed to: /opt/docohpp
echo 📝 Log files location: /var/log/docohpp/
echo 🔧 Service management: 'sudo systemctl [start^|stop^|restart^|status] docohpp'

pause
