#!/bin/bash
echo "Stopping Doc_Ohpp application..."

# Find and kill any running Java processes for our application
PIDS=$(pgrep -f "Doc_Ohpp.*jar")

if [ -n "$PIDS" ]; then
    echo "Found running application processes: $PIDS"
    for PID in $PIDS; do
        echo "Stopping process $PID"
        kill -15 $PID

        # Wait up to 30 seconds for graceful shutdown
        for i in {1..30}; do
            if ! kill -0 $PID 2>/dev/null; then
                echo "Process $PID stopped gracefully"
                break
            fi
            sleep 1
        done

        # Force kill if still running
        if kill -0 $PID 2>/dev/null; then
            echo "Force killing process $PID"
            kill -9 $PID
        fi
    done
else
    echo "No running application processes found"
fi

# Remove old PID file if exists
if [ -f /opt/docohpp/application.pid ]; then
    rm -f /opt/docohpp/application.pid
    echo "Removed old PID file"
fi

echo "Stop application script completed"