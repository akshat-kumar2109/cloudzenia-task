#!/bin/bash

set -euo pipefail
set -x

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

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Verify Docker
docker version || { echo "Docker failed to start"; exit 1; }

# Create Node.js App
mkdir -p /app
cat > /app/server.js << 'EOF'
const http = require('http');
const server = http.createServer((req, res) => {
    console.log('Request:', req.method, req.url, req.headers);
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Namaste from Container');
});
server.listen(8080, '0.0.0.0', () => {
    console.log('Server running on port 8080');
});
EOF

cat > /app/Dockerfile << 'EOF'
FROM node:16-alpine
WORKDIR /app
COPY server.js .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

# Build and run container
cd /app
docker build -t node-app .
docker run -d -p 8080:8080 --name node-app --restart always node-app || echo "Container may already be running"

# Terraform variables
instance_number=${instance_number}
domain_name=${domain_name}
ecr_url=${ecr_url}
aws_region=${aws_region}

# Cert creation
mkdir -p /etc/letsencrypt/live/${domain_name}
echo '${private_key}' > /etc/letsencrypt/live/${domain_name}/privkey.pem
echo '${certificate}' > /etc/letsencrypt/live/${domain_name}/fullchain.pem
chmod 600 /etc/letsencrypt/live/${domain_name}/*.pem

# NGINX configuration
cat > /etc/nginx/sites-available/ec2-instance${instance_number}.${domain_name} <<EOF
server {
    listen 80;
    server_name ec2-instance${instance_number}.${domain_name} ec2-alb-instance.${domain_name};

    root /var/www/html;
    index index.html;

    location / {
    }
}
server {
    listen 443 ssl;
    server_name ec2-instance${instance_number}.${domain_name} ec2-alb-instance.${domain_name};

    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

    root /var/www/html;
    index index.html;

    location / {
    }
}
EOF

cat > /etc/nginx/sites-available/ec2-docker${instance_number}.${domain_name} <<EOF
server {
    listen 80;
    server_name ec2-docker${instance_number}.${domain_name} ec2-alb-docker.${domain_name};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host ec2-docker${instance_number}.${domain_name};
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
server {
    listen 443 ssl;
    server_name ec2-docker${instance_number}.${domain_name} ec2-alb-docker.${domain_name};

    ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

    location / {
        proxy_pass https://localhost:8080;
        proxy_set_header Host ec2-docker${instance_number}.${domain_name};
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Enable NGINX sites
ln -sf /etc/nginx/sites-available/ec2-instance${instance_number}.${domain_name} /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/ec2-docker${instance_number}.${domain_name} /etc/nginx/sites-enabled/

# Create web root
mkdir -p /var/www/html
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Instance ${instance_number}</title></head>
<body><h1>Hello from Instance ${instance_number}</h1></body>
</html>
EOF

rm -rf /etc/nginx/sites-enabled/default

# Validate NGINX and restart
nginx -t && systemctl restart nginx

# CloudWatch Agent Config
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
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
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/ec2/nginx/access.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/ec2/nginx/error.log",
                        "log_stream_name": "$${aws:InstanceId}"
                    }
                ]
            }
        }
    }
}
EOF

# Install and start CloudWatch Agent
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent
