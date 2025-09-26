#!/bin/bash

# Stop application script for Doc_Ohpp Spring Boot application

# Application directory
APP_DIR="/opt/doc_ohpp"
PID_FILE="$APP_DIR/application.pid"

# Check if PID file exists
if [ ! -f $PID_FILE ]; then
    echo "PID file not found. Application may not be running."
    exit 1
fi

# Read PID from file
PID=$(cat $PID_FILE)

# Check if process is running
if ! ps -p $PID > /dev/null 2>&1; then
    echo "Process with PID $PID is not running. Removing stale PID file."
    rm -f $PID_FILE
    exit 1
fi

# Stop the application
echo "Stopping Doc_Ohpp application with PID $PID..."
kill $PID

# Wait for process to stop
sleep 5

# Check if process stopped gracefully
if ps -p $PID > /dev/null 2>&1; then
    echo "Process did not stop gracefully. Force killing..."
    kill -9 $PID
    sleep 2
fi

# Remove PID file
rm -f $PID_FILE
echo "Application stopped successfully."
