#!/bin/bash

# Start application script for Doc_Ohpp Spring Boot application
# This script starts the application in the background

# Set environment variables
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Application directory
APP_DIR="/opt/doc_ohpp"
JAR_FILE="$APP_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar"
PID_FILE="$APP_DIR/application.pid"
LOG_FILE="$APP_DIR/application.log"

# Change to application directory
cd $APP_DIR

# Check if application is already running
if [ -f $PID_FILE ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Application is already running with PID $PID"
        exit 1
    else
        echo "Removing stale PID file"
        rm -f $PID_FILE
    fi
fi

# Start the application
echo "Starting Doc_Ohpp application..."
nohup java -jar $JAR_FILE > $LOG_FILE 2>&1 &

# Save the PID
echo $! > $PID_FILE

echo "Application started with PID $(cat $PID_FILE)"
echo "Logs are available at: $LOG_FILE"
