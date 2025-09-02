#!/bin/bash

# Application Deployment Script for EC2
echo "🚀 Deploying Manufacturing QC Backend to EC2..."

# Configuration
APP_DIR="/opt/manufacturing-qc"
REPO_URL="https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git"
SERVICE_NAME="manufacturing-qc"

# Clone or update repository
if [ -d "$APP_DIR/.git" ]; then
    echo "📥 Updating existing repository..."
    cd $APP_DIR
    git pull origin main
else
    echo "📥 Cloning repository..."
    git clone $REPO_URL $APP_DIR
    cd $APP_DIR
fi

# Create production environment file
echo "⚙️ Creating production environment configuration..."
cat > .env.production << EOF
# Production Environment Configuration
DEBUG=False
API_V1_STR=/api/v1
PROJECT_NAME=Manufacturing QC Cross-Check System

# Database Configuration
DATABASE_URL=postgresql://qc_user:secure_password_here@localhost:5432/qc_system

# EasyOCR Configuration
EASYOCR_GPU=false

# File Storage
UPLOAD_DIR=/opt/manufacturing-qc/uploads
MAX_FILE_SIZE=50000000

# Security
SECRET_KEY=$(openssl rand -hex 32)

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/manufacturing-qc/app.log
EOF

# Create uploads directory
mkdir -p $APP_DIR/uploads
mkdir -p $APP_DIR/logs

# Build Docker image
echo "🐳 Building Docker image..."
docker build -t manufacturing-qc-backend .

# Stop existing container if running
echo "🛑 Stopping existing container..."
docker stop $SERVICE_NAME 2>/dev/null || true
docker rm $SERVICE_NAME 2>/dev/null || true

# Run new container
echo "🚀 Starting new container..."
docker run -d \
    --name $SERVICE_NAME \
    --restart unless-stopped \
    -p 8000:8000 \
    -v $APP_DIR/uploads:/app/uploads \
    -v $APP_DIR/logs:/app/logs \
    -v $APP_DIR/.env.production:/app/.env \
    --network host \
    manufacturing-qc-backend

# Wait for container to start
echo "⏳ Waiting for application to start..."
sleep 10

# Check if container is running
if docker ps | grep -q $SERVICE_NAME; then
    echo "✅ Application deployed successfully!"
    echo "🌐 API should be available at: http://$(curl -s ifconfig.me):8000"
    echo "📚 API docs: http://$(curl -s ifconfig.me):8000/docs"
else
    echo "❌ Deployment failed. Check logs:"
    docker logs $SERVICE_NAME
    exit 1
fi

# Setup log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/manufacturing-qc << EOF
/var/log/manufacturing-qc/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

echo "🎉 Deployment completed successfully!"
