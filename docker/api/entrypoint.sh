#!/bin/bash
set -e

echo "🚀 Starting GoUrls API..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
until PGPASSWORD=${POSTGRES_PASSWORD:-gourls_secure_password} psql -h postgres -p 5432 -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-gourls} -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "✅ PostgreSQL is ready!"

# Run Entity Framework migrations
echo "🔄 Running database migrations..."
./migrate

echo "✅ Database migrations completed!"

# Start the application
echo "🌐 Starting .NET API server..."
exec dotnet GoUrlsApi.dll