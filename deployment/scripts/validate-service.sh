#!/bin/bash

# Validate service script for Doc_Ohpp Spring Boot application
# This script checks if the application is running and responding correctly

APP_DIR="/opt/doc_ohpp"
PID_FILE="$APP_DIR/application.pid"
LOG_FILE="$APP_DIR/application.log"
APP_PORT=8080
HEALTH_ENDPOINT="http://localhost:$APP_PORT/actuator/health"

echo "Validating Doc_Ohpp application..."

# Check if PID file exists
if [ ! -f $PID_FILE ]; then
    echo "ERROR: PID file not found. Application may not be running."
    exit 1
fi

# Check if process is running
PID=$(cat $PID_FILE)
if ! ps -p $PID > /dev/null 2>&1; then
    echo "ERROR: Process with PID $PID is not running."
    exit 1
fi

echo "✓ Process is running with PID $PID"

# Check if port is listening
if ! netstat -ln | grep :$APP_PORT > /dev/null 2>&1; then
    echo "ERROR: Application is not listening on port $APP_PORT"
    exit 1
fi

echo "✓ Application is listening on port $APP_PORT"

# Check HTTP response (basic connectivity test)
if command -v curl > /dev/null 2>&1; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$APP_PORT/ || echo "000")
    if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "404" ]; then
        echo "✓ Application is responding to HTTP requests (Status: $HTTP_STATUS)"
    else
        echo "WARNING: Unexpected HTTP status: $HTTP_STATUS"
    fi
else
    echo "✓ curl not available, skipping HTTP test"
fi

# Check recent logs for errors
if [ -f $LOG_FILE ]; then
    ERROR_COUNT=$(tail -100 $LOG_FILE | grep -i "error\|exception\|failed" | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "WARNING: Found $ERROR_COUNT error(s) in recent logs"
        echo "Recent errors:"
        tail -100 $LOG_FILE | grep -i "error\|exception\|failed" | tail -5
    else
        echo "✓ No recent errors found in logs"
    fi
fi

echo "Application validation completed successfully!"
