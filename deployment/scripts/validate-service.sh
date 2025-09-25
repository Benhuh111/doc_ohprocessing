#!/bin/bash
# Validate Service Script for CodeDeploy

echo "Validating Doc_Ohpp application service..."

# Wait for application to fully start
sleep 15

# Test health endpoint
echo "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -f http://localhost:8080/api/documents/health)
if [ $? -eq 0 ]; then
    echo "✅ Health endpoint responded successfully"
    echo "Response: $HEALTH_RESPONSE"
else
    echo "❌ Health endpoint failed"
    tail -50 /var/log/docohpp/application.log
    exit 1
fi

# Test documents list endpoint
echo "Testing documents list endpoint..."
DOCS_RESPONSE=$(curl -s -f http://localhost:8080/api/documents)
if [ $? -eq 0 ]; then
    echo "✅ Documents endpoint responded successfully"
else
    echo "❌ Documents endpoint failed"
    tail -50 /var/log/docohpp/application.log
    exit 1
fi

# Check if X-Ray daemon is running
echo "Checking X-Ray daemon status..."
if systemctl is-active --quiet xray; then
    echo "✅ X-Ray daemon is running"
else
    echo "⚠️  X-Ray daemon is not running - attempting to start"
    systemctl start xray
    sleep 5
    if systemctl is-active --quiet xray; then
        echo "✅ X-Ray daemon started successfully"
    else
        echo "❌ X-Ray daemon failed to start"
        exit 1
    fi
fi

# Verify application process is running
if [ -f /opt/docohpp/app.pid ]; then
    APP_PID=$(cat /opt/docohpp/app.pid)
    if kill -0 $APP_PID 2>/dev/null; then
        echo "✅ Application process is running (PID: $APP_PID)"
    else
        echo "❌ Application process is not running"
        exit 1
    fi
else
    echo "❌ PID file not found"
    exit 1
fi

echo "🎉 Service validation completed successfully!"
