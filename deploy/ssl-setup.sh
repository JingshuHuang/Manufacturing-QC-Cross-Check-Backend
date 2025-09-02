#!/bin/bash

# SSL Setup Script for Production Deployment
echo "🔒 Setting up SSL certificate with Let's Encrypt..."

# Configuration
DOMAIN="your-domain.com"
EMAIL="your-email@example.com"

# Validate domain configuration
if [ "$DOMAIN" == "your-domain.com" ]; then
    echo "❌ Please update the DOMAIN variable in this script with your actual domain"
    exit 1
fi

if [ "$EMAIL" == "your-email@example.com" ]; then
    echo "❌ Please update the EMAIL variable in this script with your actual email"
    exit 1
fi

# Copy Nginx configuration
echo "📋 Copying Nginx configuration..."
sudo cp /opt/manufacturing-qc/deploy/nginx.conf /etc/nginx/sites-available/manufacturing-qc

# Update domain in Nginx config
sudo sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/manufacturing-qc

# Enable site
sudo ln -sf /etc/nginx/sites-available/manufacturing-qc /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed"
    exit 1
fi

# Reload Nginx
sudo systemctl reload nginx

# Obtain SSL certificate
echo "🔐 Obtaining SSL certificate..."
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

# Setup automatic renewal
echo "🔄 Setting up automatic SSL renewal..."
sudo crontab -l | { cat; echo "0 12 * * * /usr/bin/certbot renew --quiet"; } | sudo crontab -

# Test SSL renewal
sudo certbot renew --dry-run

echo "✅ SSL setup completed!"
echo "🌐 Your application should now be available at: https://$DOMAIN"
echo "📚 API docs: https://$DOMAIN/docs"
