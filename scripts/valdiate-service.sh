#!/bin/bash
echo "Validating Doc_Ohpp service..."

# Configuration
MAX_ATTEMPTS=30
ATTEMPT=0
SERVICE_URL="http://localhost:8080/api/documents/health"

# Check if PID file exists and process is running
PID_FILE="/opt/docohpp/application.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat $PID_FILE)
    if kill -0 $PID 2>/dev/null; then
        echo "Process is running with PID: $PID"
    else
        echo "ERROR: Process not running (PID file exists but process is dead)"
        exit 1
    fi
else
    echo "ERROR: PID file not found"
    exit 1
fi

# Wait for application to be ready
echo "Waiting for application to respond..."
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Checking $SERVICE_URL"

    if curl -f -s -o /dev/null "$SERVICE_URL"; then
        echo "SUCCESS: Application is responding to health check"

        # Additional API endpoint checks
        echo "Testing additional endpoints..."

        # Test stats endpoint
        if curl -f -s -o /dev/null "http://localhost:8080/api/documents/stats"; then
            echo "✓ Stats endpoint is working"
        else
            echo "⚠ Stats endpoint test failed (may be expected if no data)"
        fi

        # Test documents list endpoint
        if curl -f -s -o /dev/null "http://localhost:8080/api/documents"; then
            echo "✓ Documents list endpoint is working"
        else
            echo "⚠ Documents list endpoint test failed"
        fi

        echo "Service validation completed successfully"
        exit 0
    fi

    echo "Application not ready yet, waiting 2 seconds..."
    sleep 2
done

echo "ERROR: Application failed to respond after $MAX_ATTEMPTS attempts"
echo "Checking application logs..."

LOG_DIR="/var/log/docohpp"
if [ -f "$LOG_DIR/startup.log" ]; then
    echo "=== Startup Log ==="
    tail -20 "$LOG_DIR/startup.log"
fi

if [ -f "$LOG_DIR/application.log" ]; then
    echo "=== Application Log ==="
    tail -20 "$LOG_DIR/application.log"
fi

exit 1