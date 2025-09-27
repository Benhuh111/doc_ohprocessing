#!/bin/bash

# start-application.sh - Script to start the Doc_Ohpp application with Java 21

echo "Starting Doc_Ohpp application..."

# Set application directory
APP_DIR="/opt/docohpp"
JAR_FILE="$APP_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/application.log"

# Source environment variables
source /etc/environment 2>/dev/null || true
source /home/ec2-user/.bashrc 2>/dev/null || true
source /home/ec2-user/.java_env 2>/dev/null || true

# Find Java and verify it's Java 21
echo "Locating Java 21 installation..."

JAVA_CMD=""

# Strategy 1: Check JAVA_HOME
if [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
    echo "Found Java via JAVA_HOME: $JAVA_CMD"
fi

# Strategy 2: Check system java
if [ -z "$JAVA_CMD" ] && command -v java >/dev/null 2>&1; then
    JAVA_CMD="java"
    echo "Found Java in PATH: $(which java)"
fi

# Strategy 3: Check common locations
if [ -z "$JAVA_CMD" ]; then
    JAVA_LOCATIONS=(
        "/opt/java/bin/java"
        "/usr/bin/java"
        "/usr/lib/jvm/java-21-amazon-corretto/bin/java"
        "/usr/lib/jvm/java-21-openjdk/bin/java"
    )
    
    for location in "${JAVA_LOCATIONS[@]}"; do
        if [ -x "$location" ]; then
            JAVA_CMD="$location"
            echo "Found Java at: $JAVA_CMD"
            break
        fi
    done
fi

if [ -z "$JAVA_CMD" ]; then
    echo "❌ ERROR: No Java installation found"
    exit 1
fi

# Verify it's Java 21
echo "Verifying Java version..."
JAVA_VERSION_OUTPUT=$($JAVA_CMD -version 2>&1)
echo "Java version:"
echo "$JAVA_VERSION_OUTPUT"

if echo "$JAVA_VERSION_OUTPUT" | grep -q "21\." || echo "$JAVA_VERSION_OUTPUT" | grep -q "21+"; then
    echo "✅ Confirmed Java 21"
else
    echo "❌ ERROR: Wrong Java version. Application compiled with Java 21 but runtime is:"
    echo "$JAVA_VERSION_OUTPUT"
    echo ""
    echo "This will cause UnsupportedClassVersionError"
    exit 1
fi

# Ensure application directory exists
mkdir -p "$APP_DIR"

# Check if JAR file exists
if [ ! -f "$JAR_FILE" ]; then
    echo "❌ ERROR: JAR file not found at $JAR_FILE"
    echo "Contents of $APP_DIR:"
    ls -la "$APP_DIR/" 2>/dev/null || echo "Directory does not exist"
    exit 1
fi

# Stop any existing process
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat $PID_FILE)
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "Stopping existing application process: $OLD_PID"
        kill $OLD_PID
        sleep 3
        if ps -p $OLD_PID > /dev/null 2>&1; then
            kill -9 $OLD_PID
        fi
    fi
    rm -f "$PID_FILE"
fi

# Kill any existing Java processes
EXISTING_PROCS=$(pgrep -f "java.*Doc_Ohpp.*jar" 2>/dev/null || echo "")
if [ -n "$EXISTING_PROCS" ]; then
    echo "Stopping existing Java processes: $EXISTING_PROCS"
    for pid in $EXISTING_PROCS; do
        kill $pid 2>/dev/null
    done
    sleep 2
fi

# Start the application
echo "Starting application with Java 21..."
echo "Java command: $JAVA_CMD"
echo "JAR file: $JAR_FILE"
echo "Log file: $LOG_FILE"
echo "PID file: $PID_FILE"

cd "$APP_DIR"
nohup "$JAVA_CMD" -Xmx512m -Xms256m \
    -Dspring.profiles.active=prod \
    -Dlogging.file.name="$LOG_FILE" \
    -jar "$JAR_FILE" \
    > "$LOG_FILE" 2>&1 &

APP_PID=$!
echo $APP_PID > "$PID_FILE"
echo "Application started with PID: $APP_PID"

# Wait and verify
sleep 5
if ps -p $APP_PID > /dev/null 2>&1; then
    echo "✅ Application is running successfully with Java 21"
    sleep 10  # Give more time to initialize
    exit 0
else
    echo "❌ Application failed to start"
    if [ -f "$LOG_FILE" ]; then
        echo "--- Application log (last 30 lines) ---"
        tail -30 "$LOG_FILE"
    fi
    rm -f "$PID_FILE"
    exit 1
fi
