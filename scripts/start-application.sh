#!/bin/bash

# start-application.sh - Script to start the Doc_Ohpp application

echo "Starting Doc_Ohpp application..."

# Set application directory
APP_DIR="/opt/docohpp"
JAR_FILE="$APP_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/application.log"

# Source environment variables
source /etc/environment 2>/dev/null || true
source /home/ec2-user/.bashrc 2>/dev/null || true

# Find Java with multiple strategies
echo "Locating Java installation..."

JAVA_CMD=""

# Strategy 1: Check if java is in PATH
if command -v java >/dev/null 2>&1; then
    JAVA_CMD="java"
    echo "Found java in PATH: $(which java)"
fi

# Strategy 2: Check common locations
if [ -z "$JAVA_CMD" ]; then
    JAVA_LOCATIONS=(
        "/usr/bin/java"
        "/usr/lib/jvm/java-21-amazon-corretto/bin/java"
        "/usr/lib/jvm/java-21-openjdk/bin/java"
        "/usr/lib/jvm/java-21/bin/java"
    )
    
    for location in "${JAVA_LOCATIONS[@]}"; do
        if [ -x "$location" ]; then
            JAVA_CMD="$location"
            echo "Found Java at: $JAVA_CMD"
            break
        fi
    done
fi

# Strategy 3: Find any Java 21 installation
if [ -z "$JAVA_CMD" ]; then
    echo "Searching for Java installations..."
    JAVA_DIRS=$(find /usr/lib/jvm -name "*java-21*" -type d 2>/dev/null)
    for dir in $JAVA_DIRS; do
        if [ -x "$dir/bin/java" ]; then
            JAVA_CMD="$dir/bin/java"
            echo "Found Java at: $JAVA_CMD"
            break
        fi
    done
fi

# Strategy 4: Check alternatives
if [ -z "$JAVA_CMD" ]; then
    ALT_JAVA=$(alternatives --list | grep java | head -1 | awk '{print $3}' 2>/dev/null)
    if [ -n "$ALT_JAVA" ] && [ -x "$ALT_JAVA" ]; then
        JAVA_CMD="$ALT_JAVA"
        echo "Found Java via alternatives: $JAVA_CMD"
    fi
fi

# Final check
if [ -z "$JAVA_CMD" ]; then
    echo "ERROR: Java not found on system"
    echo "=== DEBUG INFO ==="
    echo "PATH: $PATH"
    echo "JAVA_HOME: $JAVA_HOME"
    echo "Available alternatives:"
    alternatives --list 2>/dev/null | grep java || echo "No Java alternatives"
    echo "JVM directory contents:"
    ls -la /usr/lib/jvm/ 2>/dev/null || echo "No JVM directory"
    echo "Searching entire system for java:"
    find /usr -name "java" -type f -executable 2>/dev/null | head -5
    exit 1
fi

# Verify Java works
echo "Verifying Java installation:"
$JAVA_CMD -version 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Java command failed to execute"
    exit 1
fi

# Ensure application directory exists
mkdir -p "$APP_DIR"

# Check if JAR file exists
if [ ! -f "$JAR_FILE" ]; then
    echo "Error: JAR file not found at $JAR_FILE"
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
echo "Starting application..."
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
    echo "✓ Application is running successfully"
    sleep 10  # Give more time to initialize
    exit 0
else
    echo "✗ Application failed to start"
    if [ -f "$LOG_FILE" ]; then
        echo "--- Application log ---"
        tail -20 "$LOG_FILE"
    fi
    rm -f "$PID_FILE"
    exit 1
fi
