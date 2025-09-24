#!/bin/bash
# Post-Deployment Verification Script for Doc_Ohpp
echo "=== Doc_Ohpp Post-Deployment Verification ==="

# Check application directory
echo "1. Checking /opt/docohpp directory:"
ls -la /opt/docohpp/

# Check for JAR file
echo "2. Checking for application JAR:"
if [ -f /opt/docohpp/*.jar ]; then
    echo "✓ JAR file found:"
    ls -la /opt/docohpp/*.jar
else
    echo "✗ JAR file not found"
fi

# Check application process
echo "3. Checking application process:"
if pgrep -f "doc.*ohpp" > /dev/null; then
    echo "✓ Application is running"
    ps aux | grep -v grep | grep doc.*ohpp
else
    echo "✗ Application is not running"
fi

# Check if application is listening on port 8080
echo "4. Checking port 8080:"
if netstat -tlnp | grep :8080 > /dev/null; then
    echo "✓ Application is listening on port 8080"
else
    echo "✗ Port 8080 is not listening"
fi

# Test health endpoint
echo "5. Testing health endpoint:"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/documents/health | grep -q "200"; then
    echo "✓ Health endpoint is responding"
else
    echo "✗ Health endpoint is not responding"
    echo "Trying to curl the endpoint:"
    curl -i http://localhost:8080/api/documents/health
fi

# Check logs
echo "6. Checking application logs:"
if [ -f /var/log/docohpp/application.log ]; then
    echo "✓ Application log exists"
    echo "Last 10 lines:"
    tail -10 /var/log/docohpp/application.log
else
    echo "✗ Application log not found at /var/log/docohpp/application.log"
    echo "Checking for other log locations:"
    find /opt/docohpp -name "*.log" -type f 2>/dev/null || echo "No log files found"
fi

# Check CodeDeploy agent
echo "7. Checking CodeDeploy agent:"
if sudo service codedeploy-agent status | grep -q "running"; then
    echo "✓ CodeDeploy agent is running"
else
    echo "✗ CodeDeploy agent is not running"
fi

# Check X-Ray daemon
echo "8. Checking X-Ray daemon:"
if sudo systemctl is-active xray | grep -q "active"; then
    echo "✓ X-Ray daemon is running"
else
    echo "✗ X-Ray daemon is not running"
fi

# Check CloudWatch agent
echo "9. Checking CloudWatch agent:"
if sudo systemctl is-active amazon-cloudwatch-agent | grep -q "active"; then
    echo "✓ CloudWatch agent is running"
else
    echo "✗ CloudWatch agent is not running (this is expected if not configured)"
fi

# Check Java version
echo "10. Checking Java version:"
java -version

echo "=== Verification Complete ==="
