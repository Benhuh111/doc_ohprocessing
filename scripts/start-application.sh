#!/bin/bash

# start-application.sh - Script to start the Doc_Ohpp application

echo "Starting Doc_Ohpp application..."

# Set application directory
APP_DIR="/opt/docohpp"
JAR_FILE="$APP_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/application.log"

# Ensure application directory exists
mkdir -p "$APP_DIR"

# Find Java installation
echo "Locating Java installation..."

# Common Java locations for Amazon Linux
JAVA_LOCATIONS=(
  "/usr/lib/jvm/java-21-amazon-corretto/bin/java"
  "/usr/lib/jvm/java-21-openjdk/bin/java"
  "/usr/lib/jvm/java-21/bin/java"
  "/usr/bin/java"
  "/opt/java/bin/java"
)

JAVA_CMD=""
for location in "${JAVA_LOCATIONS[@]}"; do
  if [ -x "$location" ]; then
    JAVA_CMD="$location"
    echo "Found Java at: $JAVA_CMD"
    break
  fi
done

# If not found in common locations, try to find it
if [ -z "$JAVA_CMD" ]; then
  echo "Java not found in common locations, searching..."
  
  # Try to find java executable
  JAVA_CMD=$(which java 2>/dev/null)
  
  if [ -z "$JAVA_CMD" ]; then
    # Try alternative search
    JAVA_CMD=$(find /usr -name "java" -type f -executable 2>/dev/null | head -1)
  fi
  
  if [ -z "$JAVA_CMD" ]; then
    echo "Error: Java not found on system"
    echo "Available Java installations:"
    find /usr -name "java" -type f 2>/dev/null || echo "No Java found"
    exit 1
  fi
  
  echo "Found Java at: $JAVA_CMD"
fi

# Verify Java version
echo "Verifying Java version:"
$JAVA_CMD -version 2>&1 | head -3

# Check if JAR file exists
if [ ! -f "$JAR_FILE" ]; then
  echo "Error: JAR file not found at $JAR_FILE"
  echo "Listing contents of $APP_DIR:"
  ls -la "$APP_DIR/"
  exit 1
fi

# Stop any existing process
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat $PID_FILE)
  if ps -p $OLD_PID > /dev/null 2>&1; then
    echo "Stopping existing application process: $OLD_PID"
    kill $OLD_PID
    sleep 3
    
    # Force kill if still running
    if ps -p $OLD_PID > /dev/null 2>&1; then
      kill -9 $OLD_PID
      sleep 1
    fi
  fi
  rm -f "$PID_FILE"
fi

# Kill any existing Java processes that might be our application
echo "Checking for existing Java processes..."
EXISTING_PROCS=$(pgrep -f "java.*Doc_Ohpp.*jar" 2>/dev/null || echo "")
if [ -n "$EXISTING_PROCS" ]; then
  echo "Found existing Java processes: $EXISTING_PROCS"
  for pid in $EXISTING_PROCS; do
    echo "Killing process $pid"
    kill $pid 2>/dev/null
  done
  sleep 2
  
  # Force kill any remaining
  REMAINING=$(pgrep -f "java.*Doc_Ohpp.*jar" 2>/dev/null || echo "")
  if [ -n "$REMAINING" ]; then
    for pid in $REMAINING; do
      kill -9 $pid 2>/dev/null
    done
  fi
fi

# Set JAVA_HOME if not set
if [ -z "$JAVA_HOME" ]; then
  export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
  echo "Set JAVA_HOME to: $JAVA_HOME"
fi

# Start the application
echo "Starting application with Spring profile: prod"
echo "Java command: $JAVA_CMD"
echo "JAR file: $JAR_FILE"
echo "Log file: $LOG_FILE"
echo "PID file: $PID_FILE"

# Start the application in background
cd "$APP_DIR"
nohup "$JAVA_CMD" -Xmx512m -Xms256m \
  -Dspring.profiles.active=prod \
  -Dlogging.file.name="$LOG_FILE" \
  -jar "$JAR_FILE" \
  > "$LOG_FILE" 2>&1 &

APP_PID=$!

# Save PID immediately
echo $APP_PID > "$PID_FILE"
echo "Application started with PID: $APP_PID"

# Wait a moment and check if process is still running
sleep 5
if ps -p $APP_PID > /dev/null 2>&1; then
  echo "✓ Application is running successfully with PID: $APP_PID"
  echo "✓ PID file created at: $PID_FILE"
  echo "✓ Log file: $LOG_FILE"
  
  # Give the application more time to initialize
  echo "Waiting for application to initialize..."
  sleep 10
  
  exit 0
else
  echo "✗ Application failed to start"
  echo "Checking log file for errors:"
  if [ -f "$LOG_FILE" ]; then
    echo "--- Last 20 lines of log file ---"
    tail -20 "$LOG_FILE"
  else
    echo "No log file found at $LOG_FILE"
  fi
  
  # Clean up PID file if process failed
  rm -f "$PID_FILE"
  exit 1
fi
