@echo off
REM Deploy Step Functions State Machines for Doc_Ohpp
REM This script creates Step Functions state machines for document processing workflows

setlocal EnableDelayedExpansion

REM Configuration
set REGION=eu-north-1
set ROLE_NAME=DocOhpp-StepFunctions-Role
set STATE_MACHINE_NAME_BASIC=DocOhpp-Basic-Processing
set STATE_MACHINE_NAME_ADVANCED=DocOhpp-Advanced-Processing

echo Starting Step Functions deployment for Doc_Ohpp...

REM Check prerequisites
echo Checking prerequisites...
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo ERROR: AWS CLI is not configured. Please run 'aws configure' first.
    exit /b 1
)

echo ✓ Prerequisites check passed

REM Get account ID for role ARN
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set ACCOUNT_ID=%%i
set ROLE_ARN=arn:aws:iam::%ACCOUNT_ID%:role/%ROLE_NAME%

echo Using Account ID: %ACCOUNT_ID%
echo Using Role ARN: %ROLE_ARN%

REM Check if IAM role exists
echo Checking if IAM role exists...
aws iam get-role --role-name %ROLE_NAME% >nul 2>&1
if errorlevel 1 (
    echo Creating IAM role for Step Functions...

    REM Create trust policy
    echo {
    echo   "Version": "2012-10-17",
    echo   "Statement": [
    echo     {
    echo       "Effect": "Allow",
    echo       "Principal": {
    echo         "Service": "states.amazonaws.com"
    echo       },
    echo       "Action": "sts:AssumeRole"
    echo     }
    echo   ]
    echo } > step-functions-trust-policy.json

    REM Create the role
    aws iam create-role --role-name %ROLE_NAME% --assume-role-policy-document file://step-functions-trust-policy.json

    REM Attach basic execution policy
    aws iam attach-role-policy --role-name %ROLE_NAME% --policy-arn arn:aws:iam::aws:policy/service-role/AWSStepFunctionsFullAccess

    REM Wait for role to be available
    echo Waiting for role to be available...
    timeout /t 10 /nobreak >nul

    del step-functions-trust-policy.json
    echo ✓ Created IAM role: %ROLE_NAME%
) else (
    echo ✓ IAM role already exists: %ROLE_NAME%
)

REM Deploy Basic Workflow
echo Deploying basic document processing workflow...
aws stepfunctions create-state-machine ^
    --name %STATE_MACHINE_NAME_BASIC% ^
    --definition file://document-processing-workflow.json ^
    --role-arn %ROLE_ARN% ^
    --region %REGION% >nul 2>&1

if errorlevel 1 (
    echo Updating existing basic workflow...
    aws stepfunctions update-state-machine ^
        --state-machine-arn arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_BASIC% ^
        --definition file://document-processing-workflow.json ^
        --role-arn %ROLE_ARN% ^
        --region %REGION%
    echo ✓ Updated basic workflow: %STATE_MACHINE_NAME_BASIC%
) else (
    echo ✓ Created basic workflow: %STATE_MACHINE_NAME_BASIC%
)

REM Deploy Advanced Workflow
echo Deploying advanced document processing workflow...
aws stepfunctions create-state-machine ^
    --name %STATE_MACHINE_NAME_ADVANCED% ^
    --definition file://advanced-document-workflow.json ^
    --role-arn %ROLE_ARN% ^
    --region %REGION% >nul 2>&1

if errorlevel 1 (
    echo Updating existing advanced workflow...
    aws stepfunctions update-state-machine ^
        --state-machine-arn arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_ADVANCED% ^
        --definition file://advanced-document-workflow.json ^
        --role-arn %ROLE_ARN% ^
        --region %REGION%
    echo ✓ Updated advanced workflow: %STATE_MACHINE_NAME_ADVANCED%
) else (
    echo ✓ Created advanced workflow: %STATE_MACHINE_NAME_ADVANCED%
)

REM Test Basic Workflow
echo.
echo Testing basic workflow with sample input...
set TEST_INPUT_BASIC={"documentId":"test-doc-123","fileName":"sample.pdf","contentType":"application/pdf","fileSize":2048576}

for /f "tokens=*" %%i in ('aws stepfunctions start-execution --state-machine-arn arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_BASIC% --name test-execution-basic-%RANDOM% --input "%TEST_INPUT_BASIC%" --query executionArn --output text') do set EXECUTION_ARN_BASIC=%%i

echo Started basic workflow execution: %EXECUTION_ARN_BASIC%

REM Wait for basic execution to complete
echo Waiting for basic execution to complete...
:wait_basic
timeout /t 2 /nobreak >nul
for /f "tokens=*" %%i in ('aws stepfunctions describe-execution --execution-arn %EXECUTION_ARN_BASIC% --query status --output text') do set STATUS_BASIC=%%i
if "%STATUS_BASIC%"=="RUNNING" goto wait_basic

echo Basic execution completed with status: %STATUS_BASIC%

REM Test Advanced Workflow
echo.
echo Testing advanced workflow with sample input...
set TEST_INPUT_ADVANCED={"documentId":"test-doc-456","fileName":"sample.jpg","contentType":"image/jpeg","fileSize":1024000}

for /f "tokens=*" %%i in ('aws stepfunctions start-execution --state-machine-arn arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_ADVANCED% --name test-execution-advanced-%RANDOM% --input "%TEST_INPUT_ADVANCED%" --query executionArn --output text') do set EXECUTION_ARN_ADVANCED=%%i

echo Started advanced workflow execution: %EXECUTION_ARN_ADVANCED%

REM Wait for advanced execution to complete
echo Waiting for advanced execution to complete...
:wait_advanced
timeout /t 2 /nobreak >nul
for /f "tokens=*" %%i in ('aws stepfunctions describe-execution --execution-arn %EXECUTION_ARN_ADVANCED% --query status --output text') do set STATUS_ADVANCED=%%i
if "%STATUS_ADVANCED%"=="RUNNING" goto wait_advanced

echo Advanced execution completed with status: %STATUS_ADVANCED%

REM Show results
echo.
echo 🎉 Step Functions deployment completed successfully!
echo.
echo 📋 Deployed State Machines:
echo 1. Basic Processing: arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_BASIC%
echo 2. Advanced Processing: arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_ADVANCED%
echo.
echo 🧪 Test Executions:
echo 1. Basic execution: %EXECUTION_ARN_BASIC% (Status: %STATUS_BASIC%)
echo 2. Advanced execution: %EXECUTION_ARN_ADVANCED% (Status: %STATUS_ADVANCED%)
echo.
echo 🔗 View in AWS Console:
echo 1. Step Functions Console: https://%REGION%.console.aws.amazon.com/states/home?region=%REGION%#/statemachines
echo 2. Basic Workflow: https://%REGION%.console.aws.amazon.com/states/home?region=%REGION%#/statemachines/view/arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_BASIC%
echo 3. Advanced Workflow: https://%REGION%.console.aws.amazon.com/states/home?region=%REGION%#/statemachines/view/arn:aws:states:%REGION%:%ACCOUNT_ID%:stateMachine:%STATE_MACHINE_NAME_ADVANCED%
echo.
echo 📖 Next Steps:
echo 1. Open the Step Functions console to view workflow diagrams
echo 2. Check execution history and results
echo 3. Test with different input parameters
echo 4. Export workflow diagrams for documentation

pause
