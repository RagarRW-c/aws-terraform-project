#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install necessary packages
apt-get install -y \
    nginx \
    postgresql-client \
    python3-pip \
    git \
    curl \
    wget \
    unzip

# Configure nginx
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Pearson DevOps Project</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
        }
        .status {
            background: #4CAF50;
            color: white;
            padding: 10px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Pearson DevOps Project</h1>
        <div class="status">✅ Server is running successfully!</div>
        <p><strong>Environment:</strong> AWS EC2 + RDS</p>
        <p><strong>Managed by:</strong> Terraform + GitHub Actions</p>
        <p><strong>Hostname:</strong> $(hostname)</p>
        <p><strong>Date:</strong> $(date)</p>
    </div>
</body>
</html>
EOF

# Start nginx
systemctl enable nginx
systemctl restart nginx

# Create a log file
echo "EC2 instance initialized at $(date)" > /var/log/user-data.log
echo "All packages installed successfully" >> /var/log/user-data.log