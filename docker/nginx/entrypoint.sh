#!/bin/sh
set -e

echo "🚀 Starting GoUrls Reverse Proxy..."

# Wait for backend services to be ready
echo "⏳ Waiting for backend services..."

# Wait for API
until curl -f http://api:5000/api/urls > /dev/null 2>&1; do
    echo "Waiting for API service..."
    sleep 2
done

# Wait for frontend
until curl -f http://frontend:80/health > /dev/null 2>&1; do
    echo "Waiting for frontend service..."
    sleep 2
done

echo "✅ Backend services are ready!"

# Test nginx configuration
nginx -t

echo "🌐 Starting nginx reverse proxy..."
exec "$@"