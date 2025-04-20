#!/bin/bash

# Enable debug mode and error handling
set -x
set -e

# Update system packages
apt-get update
apt-get install -y ca-certificates curl gnupg net-tools

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker and NGINX
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin nginx awscli

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify Docker is running
docker --version
systemctl status docker

# Create a simple Node.js application for Docker
mkdir -p /app
cat > /app/server.js << 'EOL'
const http = require('http');

const server = http.createServer((req, res) => {
    console.log('Received request:', req.method, req.url, req.headers);
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Namaste from Container');
});

server.listen(8080, '0.0.0.0', () => {
    console.log('Server running on port 8080');
});
EOL

cat > /app/Dockerfile << 'EOL'
FROM node:16-alpine
WORKDIR /app
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
EOL

# Build and run Docker container
cd /app
docker build -t node-app .
docker run -d -p 8080:8080 --name node-app --restart always node-app

# Verify container is running
docker ps
curl -v http://localhost:8080/

# Stop NGINX if running
systemctl stop nginx

# Create directories for certificates
mkdir -p /etc/nginx/certs
cd /etc/nginx/certs

# Download the certificates from ACM (using the instance role)
aws acm get-certificate --certificate-arn ${acm_certificate_arn} --region ${aws_region} | jq -r '.Certificate' > server.crt
aws acm get-certificate --certificate-arn ${acm_certificate_arn} --region ${aws_region} | jq -r '.CertificateChain' > chain.crt
aws acm get-certificate --certificate-arn ${acm_certificate_arn} --region ${aws_region} | jq -r '.PrivateKey' > server.key

# Combine certificate and chain for NGINX
cat server.crt chain.crt > fullchain.crt

# Set proper permissions
chmod 600 server.key
chmod 644 fullchain.crt

# Remove default NGINX configuration
rm -f /etc/nginx/sites-enabled/default

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
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create NGINX server configuration
cat > /etc/nginx/conf.d/default.conf << 'EOL'
# Default server to redirect HTTP to HTTPS
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

# Instance server (direct)
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ec2-instance${instance_number}.${domain_name};

    ssl_certificate /etc/nginx/certs/fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    access_log /var/log/nginx/instance.access.log main;
    error_log /var/log/nginx/instance.error.log debug;

    location / {
        add_header Content-Type text/plain;
        return 200 'Hello from Instance';
    }
}

# Docker server (direct)
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ec2-docker${instance_number}.${domain_name};

    ssl_certificate /etc/nginx/certs/fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    access_log /var/log/nginx/docker.access.log main;
    error_log /var/log/nginx/docker.error.log debug;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
    }
}

# ALB Instance server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ec2-alb-instance.${domain_name};

    ssl_certificate /etc/nginx/certs/fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    access_log /var/log/nginx/alb-instance.access.log main;
    error_log /var/log/nginx/alb-instance.error.log debug;

    location / {
        add_header Content-Type text/plain;
        return 200 'Hello from Instance';
    }
}

# ALB Docker server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ec2-alb-docker.${domain_name};

    ssl_certificate /etc/nginx/certs/fullchain.crt;
    ssl_certificate_key /etc/nginx/certs/server.key;

    access_log /var/log/nginx/alb-docker.access.log main;
    error_log /var/log/nginx/alb-docker.error.log debug;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
    }
}
EOL

# Replace placeholders
sed -i "s/\${instance_number}/${instance_number}/g" /etc/nginx/conf.d/default.conf
sed -i "s/\${domain_name}/${domain_name}/g" /etc/nginx/conf.d/default.conf

# Create log directories
mkdir -p /var/log/nginx
chown -R www-data:www-data /var/log/nginx

# Test NGINX configuration
nginx -t

# Start NGINX
systemctl enable nginx
systemctl restart nginx

# Verify services are running
echo "Verifying services..."
systemctl status nginx
docker ps
netstat -tlpn | grep -E ":(80|8080)"

# Test endpoints
echo "Testing endpoints..."
curl -v -H "Host: ec2-instance${instance_number}.${domain_name}" http://localhost/
curl -v -H "Host: ec2-docker${instance_number}.${domain_name}" http://localhost/

# Configure CloudWatch agent
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOL'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
    },
    "metrics": {
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent"],
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
                        "file_path": "/var/log/nginx/default.access.log",
                        "log_group_name": "/ec2/nginx/default.access.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/default.error.log",
                        "log_group_name": "/ec2/nginx/default.error.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/instance.access.log",
                        "log_group_name": "/ec2/nginx/instance.access.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/instance.error.log",
                        "log_group_name": "/ec2/nginx/instance.error.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/docker.access.log",
                        "log_group_name": "/ec2/nginx/docker.access.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/docker.error.log",
                        "log_group_name": "/ec2/nginx/docker.error.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    }
                ]
            }
        }
    }
}
EOL

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

# Final verification
echo "Setup complete. Final verification..."
ps aux | grep nginx
ps aux | grep docker
netstat -tlpn | grep -E ":(80|8080)"
curl -v http://localhost:8080/ 