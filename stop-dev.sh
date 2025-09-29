#!/bin/bash

# GoUrls Development Stop Script
echo "Stopping GoUrls development environment..."

# Stop nginx
echo "Stopping nginx..."
sudo nginx -s stop

if [ $? -eq 0 ]; then
    echo "✅ nginx stopped successfully"
else
    echo "⚠️  nginx might not be running or failed to stop"
fi

echo ""
echo "🛑 Development environment stopped"
echo ""
echo "Remember to also stop your Angular dev server (Ctrl+C in the terminal where ng serve is running)"