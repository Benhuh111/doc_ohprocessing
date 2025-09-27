#!/bin/bash

# validate-service.sh - Validate that the Doc_Ohpp service is running correctly

echo "Validating Doc_Ohpp service..."

# Application settings
APP_DIR="/opt/docohpp"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/application.log"

# Wait for application to fully start
echo "Waiting for application to fully initialize..."
sleep 15

# Check application directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "✗ Application directory not found: $APP_DIR"
  exit 1
fi

echo "Checking application directory contents:"
ls -la "$APP_DIR/"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
  echo "✗ PID file not found at: $PID_FILE"
  echo "Searching for Java processes that might be our application:"
  
  JAVA_PROCS=$(pgrep -f "java.*Doc_Ohpp.*jar" 2>/dev/null || echo "")
  if [ -n "$JAVA_PROCS" ]; then
    echo "Found Java processes: $JAVA_PROCS"
    # Create PID file with the first found process
    FIRST_PID=$(echo $JAVA_PROCS | cut -d' ' -f1)
    echo $FIRST_PID > "$PID_FILE"
    echo "Created PID file with PID: $FIRST_PID"
  else
    echo "✗ No Java processes found for Doc_Ohpp"
    
    if [ -f "$LOG_FILE" ]; then
      echo "--- Application log (last 20 lines) ---"
      tail -20 "$LOG_FILE"
    fi
    
    exit 1
  fi
fi

# Check if process is running
if [ -f "$PID_FILE" ]; then
  PID=$(cat $PID_FILE)
  if ps -p $PID > /dev/null 2>&1; then
    echo "✓ Application process is running (PID: $PID)"
  else
    echo "✗ Application process not found for PID: $PID"
    rm -f "$PID_FILE"
    exit 1
  fi
else
  echo "✗ Still no PID file found"
  exit 1
fi

# Test health endpoint with retries
echo "Testing health endpoint..."
HEALTH_URL="http://localhost:8080/api/documents/health"

# Wait up to 90 seconds for application to be ready
MAX_ATTEMPTS=18
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Testing $HEALTH_URL"
  
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $HEALTH_URL 2>/dev/null || echo "000")
  
  if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✓ Health check passed (HTTP $HTTP_STATUS)"
    
    # Test additional endpoints if health passes
    echo "Testing stats endpoint..."
    STATS_URL="http://localhost:8080/api/documents/stats"
    STATS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $STATS_URL 2>/dev/null || echo "000")
    
    if [ "$STATS_STATUS" -eq 200 ]; then
      echo "✓ Stats endpoint accessible (HTTP $STATS_STATUS)"
    else
      echo "⚠ Stats endpoint returned HTTP $STATS_STATUS (this is acceptable)"
    fi
    
    # Test list endpoint
    LIST_URL="http://localhost:8080/api/documents"
    LIST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 $LIST_URL 2>/dev/null || echo "000")
    
    if [ "$LIST_STATUS" -eq 200 ]; then
      echo "✓ List endpoint accessible (HTTP $LIST_STATUS)"
    fi
    
    echo "✅ Service validation successful - all critical endpoints are responding"
    exit 0
    
  elif [ "$HTTP_STATUS" -eq 000 ]; then
    echo "⚠ Connection failed, retrying in 5 seconds... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  else
    echo "⚠ Health check returned HTTP $HTTP_STATUS, retrying in 5 seconds... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  fi
  
  sleep 5
  ATTEMPT=$((ATTEMPT + 1))
done

echo "✗ Service validation failed - health endpoint not responding after $MAX_ATTEMPTS attempts"
echo ""
echo "=== DEBUGGING INFORMATION ==="
echo "Process status:"
if [ -f "$PID_FILE" ]; then
  PID=$(cat $PID_FILE)
  ps -p $PID || echo "Process $PID not found"
fi

echo ""
echo "Network status:"
netstat -tlnp | grep :8080 || echo "Port 8080 not listening"

echo ""
echo "Application logs (last 30 lines):"
if [ -f "$LOG_FILE" ]; then
  tail -30 "$LOG_FILE"
else
  echo "No log file found at $LOG_FILE"
fi

echo ""
echo "Java processes:"
pgrep -f java || echo "No Java processes found"

exit 1
