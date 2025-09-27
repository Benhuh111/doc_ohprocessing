#!/bin/bash
   
# stop-application.sh - Script to stop the Doc_Ohpp application
   
echo "Stopping Doc_Ohpp application..."
   
# Check if application is running
PID_FILE=/opt/docohpp/app.pid
   
if [ -f "$PID_FILE" ]; then
  PID=$(cat $PID_FILE)
     
  if ps -p $PID > /dev/null; then
    echo "Stopping application process with PID: $PID"
    kill $PID
    sleep 5
       
    # Force kill if still running
    if ps -p $PID > /dev/null; then
      echo "Application still running, force killing process"
      kill -9 $PID
    fi
       
    rm $PID_FILE
    echo "Application stopped successfully"
  else
    echo "No running process found with PID: $PID"
    rm $PID_FILE
  fi
else
  echo "PID file not found, application may not be running"
fi
   
# Check for any Java processes that might be our application
JAVA_PROCS=$(pgrep -f "java.*Doc_Ohpp.*jar" || echo "")
   
if [ -n "$JAVA_PROCS" ]; then
  echo "Found additional Java processes that may be Doc_Ohpp: $JAVA_PROCS"
  echo "Attempting to stop these processes"
     
  for pid in $JAVA_PROCS; do
    echo "Stopping process $pid"
    kill $pid
  done
     
  sleep 2
     
  # Force kill if any still running
  REMAINING_PROCS=$(pgrep -f "java.*Doc_Ohpp.*jar" || echo "")
  if [ -n "$REMAINING_PROCS" ]; then
    echo "Force killing remaining processes: $REMAINING_PROCS"
    for pid in $REMAINING_PROCS; do
      kill -9 $pid
    done
  fi
fi
   
echo "Application stop procedure completed"
exit 0
