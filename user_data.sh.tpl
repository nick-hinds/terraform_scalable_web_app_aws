#!/bin/bash
set -e

# Update system
yum update -y

# Install necessary packages
yum install -y amazon-cloudwatch-agent aws-cli jq docker

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/application/*.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/application"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "CustomApp",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_IDLE",
            "unit": "Percent"
          }
        ],
        "totalcpu": false,
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Get database credentials from Secrets Manager
if [ ! -z "${db_secret_arn}" ]; then
  SECRET=$(aws secretsmanager get-secret-value --secret-id ${db_secret_arn} --region ${aws_region} --query SecretString --output text)
  export DB_USERNAME=$(echo $SECRET | jq -r .username)
  export DB_PASSWORD=$(echo $SECRET | jq -r .password)
fi

# Set environment variables
cat > /etc/environment <<EOF
ENVIRONMENT=${environment}
AWS_REGION=${aws_region}
S3_BUCKET=${s3_bucket}
APP_PORT=${app_port}
EOF

# Create application directory
mkdir -p /var/log/application
mkdir -p /opt/application

# Simple health check endpoint (replace with your actual application)
cat > /opt/application/health_check.py <<'PYTHON'
#!/usr/bin/env python3
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'status': 'healthy',
                'environment': os.environ.get('ENVIRONMENT', 'unknown'),
                'region': os.environ.get('AWS_REGION', 'unknown')
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

if __name__ == '__main__':
    port = int(os.environ.get('APP_PORT', 8080))
    server = HTTPServer(('', port), HealthHandler)
    print(f'Health check server running on port {port}')
    server.serve_forever()
PYTHON

chmod +x /opt/application/health_check.py

# Create systemd service for the application
cat > /etc/systemd/system/application.service <<EOF
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/application
ExecStart=/usr/bin/python3 /opt/application/health_check.py
Restart=always
RestartSec=10
StandardOutput=append:/var/log/application/app.log
StandardError=append:/var/log/application/app.log
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

# Start the application service
systemctl daemon-reload
systemctl enable application
systemctl start application

# Signal completion
echo "User data script completed successfully" >> /var/log/user-data.log
