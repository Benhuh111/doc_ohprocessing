#!/bin/bash
echo "Starting Doc_Ohpp application..."

# Set variables
APP_DIR="/opt/docohpp"
LOG_DIR="/var/log/docohpp"
JAR_FILE=$(find $APP_DIR -name "*.jar" | head -1)
PID_FILE="$APP_DIR/application.pid"

# Check if JAR file exists
if [ -z "$JAR_FILE" ]; then
    echo "ERROR: No JAR file found in $APP_DIR"
    exit 1
fi

echo "Found JAR file: $JAR_FILE"

# Set up environment variables
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
export PATH=$JAVA_HOME/bin:$PATH

# AWS credentials should be available through EC2 instance role
export AWS_REGION=eu-north-1

# JVM options
JAVA_OPTS="-Xms512m -Xmx1024m"
JAVA_OPTS="$JAVA_OPTS -server"
JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true"
JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF-8"
JAVA_OPTS="$JAVA_OPTS -Dspring.profiles.active=production"

# Application properties
APP_OPTS="--server.port=8080"
APP_OPTS="$APP_OPTS --logging.file.name=$LOG_DIR/application.log"
APP_OPTS="$APP_OPTS --logging.level.com.example=INFO"
APP_OPTS="$APP_OPTS --aws.region=eu-north-1"

# Start the application
echo "Starting application with command:"
echo "nohup java $JAVA_OPTS -jar $JAR_FILE $APP_OPTS"

cd $APP_DIR
nohup java $JAVA_OPTS -jar $JAR_FILE $APP_OPTS > $LOG_DIR/startup.log 2>&1 &

# Save PID
echo $! > $PID_FILE
PID=$(cat $PID_FILE)

echo "Application started with PID: $PID"

# Wait a moment for startup
sleep 5

# Check if process is still running
if kill -0 $PID 2>/dev/null; then
    echo "Application is running successfully"
    echo "Logs available at: $LOG_DIR/"
    echo "Application URL: http://localhost:8080"
    exit 0
else
    echo "ERROR: Application failed to start"
    echo "Check startup logs: $LOG_DIR/startup.log"
    exit 1
fi
