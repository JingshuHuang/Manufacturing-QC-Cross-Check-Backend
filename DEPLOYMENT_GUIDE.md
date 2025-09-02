# Complete Manufacturing QC Project Deployment Guide

## 🚀 Quick Deployment Steps

### 1. Connect to your EC2 instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 2. Install dependencies (if not already installed)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git and other tools
sudo apt install -y git curl
```

### 3. Deploy the complete project
```bash
# Download and run the deployment script
curl -O https://raw.githubusercontent.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend/main/deploy/deploy-full.sh
chmod +x deploy-full.sh
sudo ./deploy-full.sh
```

### Alternative: Manual deployment
```bash
# Create directory
sudo mkdir -p /opt/manufacturing-qc
cd /opt/manufacturing-qc

# Clone repositories
sudo git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Backend.git
sudo git clone https://github.com/JingshuHuang/Manufacturing-QC-Cross-Check-Frontend.git

# Change to backend directory
cd Manufacturing-QC-Cross-Check-Backend

# Create environment file
sudo tee .env << EOF
DB_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -hex 32)
NODE_ENV=production
DEBUG=false
EOF

# Deploy
sudo docker-compose -f docker-compose.full.yml up -d --build
```

## 🔧 Key Changes Made

### 1. Fixed Port Conflicts
- ✅ Removed external PostgreSQL port mapping (5432)
- ✅ Database now only accessible internally via Docker network
- ✅ All external traffic goes through port 80 (HTTP)

### 2. Added Complete Frontend Integration
- ✅ React frontend builds as separate Docker container
- ✅ Nginx serves both frontend and routes API calls to backend
- ✅ Proper CORS configuration for API communication

### 3. Improved Service Configuration
- ✅ All services use internal Docker networking
- ✅ Nginx reverse proxy handles all external traffic
- ✅ Environment variables properly configured
- ✅ Health checks and service dependencies

### 4. Enhanced Deployment Process
- ✅ Automatic cleanup of conflicting services
- ✅ Better error handling and logging
- ✅ Systemd service for auto-restart on boot
- ✅ Log rotation setup

## 📍 Access Points After Deployment

- **Complete Application**: `http://your-ec2-ip/`
- **Backend API**: `http://your-ec2-ip/api/`
- **API Documentation**: `http://your-ec2-ip/docs`
- **Health Check**: `http://your-ec2-ip/health`

## 🔒 Security Notes

1. **Database**: Only accessible internally, no external port exposure
2. **Credentials**: Securely generated and displayed during deployment
3. **HTTPS**: Ready for SSL certificate setup with Let's Encrypt

## 🐛 Troubleshooting

### Check service status:
```bash
cd /opt/manufacturing-qc/Manufacturing-QC-Cross-Check-Backend
sudo docker-compose -f docker-compose.full.yml ps
```

### View logs:
```bash
# All services
sudo docker-compose -f docker-compose.full.yml logs

# Specific service
sudo docker-compose -f docker-compose.full.yml logs [app|frontend|db|nginx]
```

### Restart services:
```bash
sudo docker-compose -f docker-compose.full.yml restart
```

### Complete rebuild:
```bash
sudo docker-compose -f docker-compose.full.yml down
sudo docker-compose -f docker-compose.full.yml up -d --build
```

## 🔄 Updating the Application

```bash
cd /opt/manufacturing-qc/Manufacturing-QC-Cross-Check-Backend
sudo git pull origin main
cd ../Manufacturing-QC-Cross-Check-Frontend
sudo git pull origin main
cd ../Manufacturing-QC-Cross-Check-Backend
sudo docker-compose -f docker-compose.full.yml up -d --build
```
