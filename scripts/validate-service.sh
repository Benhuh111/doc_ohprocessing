#!/bin/bash

# validate-service.sh - Validate that the Doc_Ohpp service is running correctly

APP_DIR="/opt/doc_ohpp"
PID_FILE="$APP_DIR/application.pid"
LOG_FILE="$APP_DIR/application.log"
echo "Validating Doc_Ohpp service..."

# Wait for application to start
sleep 10

# Check if process is running
PID_FILE="/opt/docohpp/app.pid"
if [ -f "$PID_FILE" ]; then
  PID=$(cat $PID_FILE)
  if ps -p $PID > /dev/null; then
    echo "✓ Application process is running (PID: $PID)"
  else
    echo "✗ Application process not found"
    exit 1
  fi
else
  echo "✗ PID file not found"
  exit 1
fi

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_URL="http://localhost:8080/api/documents/health"

# Wait up to 60 seconds for application to be ready
for i in {1..12}; do
  echo "Attempt $i: Testing $HEALTH_URL"
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL || echo "000")
  
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✓ Health check passed (HTTP $HTTP_STATUS)"
    
    # Test additional endpoints
    STATS_URL="http://localhost:8080/api/documents/stats"
    STATS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $STATS_URL || echo "000")
    
    if [ "$STATS_STATUS" -eq 200 ]; then
      echo "✓ Stats endpoint accessible (HTTP $STATS_STATUS)"
    fi
    
    echo "✓ Service validation successful"
    exit 0
  else
    echo "⚠ Health check returned HTTP $HTTP_STATUS, retrying in 5 seconds..."
    sleep 5
  fi
done

echo "✗ Service validation failed - health endpoint not responding"
echo "Checking application logs..."
tail -20 /opt/docohpp/application.log || echo "No log file found"

exit 1
