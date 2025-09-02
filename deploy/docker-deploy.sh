#!/bin/bash

# Production Deployment with Docker Compose
echo "🐳 Deploying Manufacturing QC Backend with Docker Compose..."

# Configuration
APP_DIR="/opt/manufacturing-qc"
SERVICE_NAME="manufacturing-qc"

# Generate secure database password
DB_PASSWORD=$(openssl rand -base64 32)

# Create environment file for Docker Compose
cat > .env << EOF
# Database Configuration
DB_PASSWORD=$DB_PASSWORD

# Application Environment
NODE_ENV=production
DEBUG=false
EOF

# Create production environment file for the application
cat > .env.production << EOF
# Production Environment Configuration
DEBUG=false
API_V1_STR=/api/v1
PROJECT_NAME=Manufacturing QC Cross-Check System

# Database Configuration
DATABASE_URL=postgresql://qc_user:$DB_PASSWORD@localhost:5432/qc_system

# EasyOCR Configuration
EASYOCR_GPU=false

# File Storage
UPLOAD_DIR=/app/uploads
MAX_FILE_SIZE=50000000

# Security
SECRET_KEY=$(openssl rand -hex 32)

# Logging
LOG_LEVEL=INFO
LOG_FILE=/app/logs/app.log
EOF

# Create necessary directories
mkdir -p uploads logs

# Initialize database
echo "🗄️ Creating database initialization script..."
cat > deploy/init-db.sql << EOF
-- Initialize QC System Database
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant additional permissions
GRANT CREATE ON SCHEMA public TO qc_user;
GRANT USAGE ON SCHEMA public TO qc_user;
EOF

# Stop existing services
echo "🛑 Stopping existing services..."
docker-compose -f docker-compose.prod.yml down

# Build and start services
echo "🚀 Building and starting services..."
docker-compose -f docker-compose.prod.yml up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🔍 Checking service health..."
if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "✅ Services started successfully!"
    
    # Run database migrations
    echo "🔄 Running database migrations..."
    docker-compose -f docker-compose.prod.yml exec -T app alembic upgrade head
    
    echo "🎉 Deployment completed successfully!"
    echo "🌐 API available at: http://$(curl -s ifconfig.me)"
    echo "📚 API docs: http://$(curl -s ifconfig.me)/docs"
    echo "🗄️ Database password: $DB_PASSWORD"
    echo "📝 Save this password securely!"
else
    echo "❌ Deployment failed. Checking logs..."
    docker-compose -f docker-compose.prod.yml logs
    exit 1
fi
