#!/bin/bash

# GoUrls Development Setup Script
echo "Setting up GoUrls local development environment..."

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    brew install nginx
else
    echo "nginx is already installed"
fi

# Add go to hosts file if not already present
if ! grep -q "127.0.0.1   go$" /etc/hosts; then
    echo "Adding go to hosts file..."
    echo "127.0.0.1   go" | sudo tee -a /etc/hosts
else
    echo "go already exists in hosts file"
fi

# Copy nginx configuration
echo "Setting up nginx configuration..."
sudo cp nginx-go-proxy.conf /opt/homebrew/etc/nginx/servers/

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Setup complete!"
    echo ""
    echo "To start the development environment:"
    echo "1. Run './start-dev.sh' to start nginx and Angular"
    echo "2. Access your app at http://go.local"
    echo "3. Short URLs will work as http://go.local/shortname"
else
    echo "❌ nginx configuration error. Please check the setup."
fi