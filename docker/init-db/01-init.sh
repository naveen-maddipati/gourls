#!/bin/bash
set -e

# Database initialization script for GoUrls
echo "🚀 Initializing GoUrls database..."

# Create database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Enable necessary extensions
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    -- Create indexes for better performance
    -- (Entity Framework migrations will create the tables)
    
    -- Set default timezone
    SET timezone = 'UTC';
    
    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
EOSQL

echo "✅ Database initialization completed!"