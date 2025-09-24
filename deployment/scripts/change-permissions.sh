echo "Setting up file permissions..."

# Set ownership
chown -R ec2-user:ec2-user /opt/docohpp
chown -R ec2-user:ec2-user /var/log/docohpp

# Set permissions for application directory
chmod -R 755 /opt/docohpp
chmod -R 644 /opt/docohpp/*.jar 2>/dev/null || echo "No JAR files found yet"

# Make scripts executable
chmod +x /opt/docohpp/scripts/*.sh 2>/dev/null || echo "No script files found"

# Set log directory permissions
chmod 755 /var/log/docohpp

echo "Permissions setup completed"
