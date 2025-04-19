#!/bin/bash

# Enable debug mode and error handling
set -x
set -e

# Update system packages
apt-get update
apt-get install -y nginx awscli docker.io

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Wait for Docker to be ready
while ! docker info > /dev/null 2>&1; do
    echo "Waiting for Docker to be ready..."
    sleep 1
done

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${ecr_url}

# Pull and run Docker container
docker pull ${ecr_url}:latest || echo "Failed to pull image, will be pulled when available"
docker run -d -p 8080:8080 --name node-app --restart always ${ecr_url}:latest || echo "Failed to start container, will start when image is available"

# Stop NGINX if running
systemctl stop nginx || true

# Remove all existing NGINX configuration
rm -f /etc/nginx/conf.d/*.conf
rm -f /etc/nginx/sites-enabled/*

# Configure NGINX
cat > /etc/nginx/nginx.conf << 'EOL'
user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log debug;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    keepalive_timeout 65;

    # Disable any automatic HTTPS redirects
    absolute_redirect off;
    port_in_redirect off;
    server_tokens off;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create NGINX configuration for the instance
cat > /etc/nginx/conf.d/instance.conf << 'EOL'
# Default server for health checks
server {
    listen 80 default_server;
    server_name _;

    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }

    location / {
        return 404;
    }
}

server {
    listen 80;
    server_name ec2-instance${instance_number}.${domain_name};

    location / {
        return 200 'Hello from Instance';
        add_header Content-Type text/plain;
    }

    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}

server {
    listen 80;
    server_name ec2-docker${instance_number}.${domain_name};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:8080/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL

# Replace placeholders in the NGINX configuration
sed -i "s/INSTANCE_NUMBER/${instance_number}/g" /etc/nginx/conf.d/instance.conf
sed -i "s/DOMAIN_NAME/${domain_name}/g" /etc/nginx/conf.d/instance.conf

# Create log directories with proper permissions
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx

# Start NGINX
systemctl start nginx
systemctl enable nginx

# Configure CloudWatch agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
chown -R root:root /opt/aws/amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOL'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root",
        "region": "us-west-2"
    },
    "metrics": {
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": ["swap_used_percent"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["disk_used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["/"]
            }
        },
        "append_dimensions": {
            "InstanceId": "$${aws:InstanceId}"
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/health_check.log",
                        "log_group_name": "/ec2/nginx/health_check.log",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/health_check_error.log",
                        "log_group_name": "/ec2/nginx/health_check_error.log",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/docker_access.log",
                        "log_group_name": "/ec2/nginx/docker_access.log",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/docker_error.log",
                        "log_group_name": "/ec2/nginx/docker_error.log",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/ec2/nginx/error.log",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/ec2/messages",
                        "log_stream_name": "$${aws:InstanceId}",
                        "timezone": "UTC"
                    }
                ]
            }
        },
        "force_flush_interval": 15
    }
}
EOL

# Stop CloudWatch agent if running
systemctl stop amazon-cloudwatch-agent || true

# Start CloudWatch agent with new configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent

# Verify CloudWatch agent is running
if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
    echo "CloudWatch agent failed to start"
    systemctl status amazon-cloudwatch-agent
    journalctl -u amazon-cloudwatch-agent
    exit 1
fi

# Final verification
echo "Instance setup complete. Verifying services..."
systemctl status nginx
systemctl status docker
systemctl status amazon-cloudwatch-agent
docker ps

# Create test log entries
echo "Test log entry from instance startup - $(date)" >> /var/log/nginx/health_check.log
echo "Test log entry from instance startup - $(date)" >> /var/log/nginx/error.log 