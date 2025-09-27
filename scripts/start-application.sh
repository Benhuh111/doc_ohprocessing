#!/bin/bash
echo "Starting Doc_Ohpp application (quick start)..."
cd /opt/docohpp
nohup java -jar Doc_Ohpp-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod > application.log 2>&1 &
echo "Application started"
