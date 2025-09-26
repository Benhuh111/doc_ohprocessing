#!/bin/bash

# Simple start script for Doc_Ohpp application
# Run this from your home directory on EC2

APP_DIR="/home/ec2-user"
JAR_FILE="$APP_DIR/Doc_Ohpp-0.0.1-SNAPSHOT.jar"
PID_FILE="$APP_DIR/app.pid"
LOG_FILE="$APP_DIR/app.log"

cd $APP_DIR

# Check if application is already running
if [ -f $PID_FILE ]; then
    PID=$(cat $PID_FILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Application is already running with PID $PID"
        echo "To stop it, run: kill $PID"
        exit 1
    else
        echo "Removing stale PID file"
        rm -f $PID_FILE
    fi
fi

# Check if port is already in use
if netstat -ln | grep :8080 > /dev/null 2>&1; then
    echo "Port 8080 is already in use. Finding the process..."
    EXISTING_PID=$(sudo netstat -tlnp | grep :8080 | awk '{print $7}' | cut -d'/' -f1)
    echo "Process $EXISTING_PID is using port 8080"
    echo "To stop it, run: sudo kill $EXISTING_PID"
    exit 1
fi

echo "Starting Doc_Ohpp application..."
echo "Logs will be written to: $LOG_FILE"
echo "Access your app at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"

# Start the application in background
nohup java -jar $JAR_FILE > $LOG_FILE 2>&1 &

# Save the PID
echo $! > $PID_FILE

echo "Application started with PID $(cat $PID_FILE)"
echo "To stop the application, run: kill $(cat $PID_FILE)"
echo "To view logs, run: tail -f $LOG_FILE"
