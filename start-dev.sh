#!/bin/bash

# GoUrls Development Start Script
echo "Starting GoUrls development environment..."

# Start nginx
echo "Starting nginx..."
sudo nginx

# Check if nginx started successfully
if [ $? -eq 0 ]; then
    echo "✅ nginx started successfully"
else
    echo "❌ Failed to start nginx"
    exit 1
fi

echo ""
echo "🚀 Development environment is ready!"
echo ""
echo "📱 Access your app at: http://go"
echo "🔗 Short URLs work as: http://go/shortname"
echo ""
echo "To stop nginx: sudo nginx -s stop"
echo "To reload nginx config: sudo nginx -s reload"
echo ""
echo "Don't forget to start your Angular dev server:"
echo "cd go-urls-app && ng serve"