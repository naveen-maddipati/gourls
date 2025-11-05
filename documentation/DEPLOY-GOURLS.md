# 🐳 GoUrls Docker Deployment Guide

This document provides comprehensive instructions for deploying GoUrls as a self-sustaining Docker containerized solution.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment Commands](#deployment-commands)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

The GoUrls Docker deployment creates a complete, self-sustaining environment with:
- **PostgreSQL Database** (persistent data storage)
- **.NET Core API** (backend services)
- **Angular Frontend** (user interface)
- **nginx Reverse Proxy** (routing and load balancing)

All services run in isolated containers with proper networking, health checks, and automatic restarts.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Host                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │    nginx    │    │  Angular    │    │  .NET API   │     │
│  │   (proxy)   │◄──►│ (frontend)  │◄──►│ (backend)   │     │
│  │   Port 80   │    │  Container  │    │  Port 5000  │     │
│  │             │    │             │    │             │     │
│  │ Go Links:   │    │ Management  │    │ CRUD & Auth │     │
│  │ /shortname  │    │ Interface   │    │ Operations  │     │
│  │ ↓ 302       │    │             │    │             │     │
│  │ Redirect    │    │             │    │             │     │
│  └─────────────┘    └─────────────┘    └─────┬───────┘     │
│         │                                     │             │
│         │   API Routes: /api/*               │             │
│         │   Frontend: /*                     │             │
│         │   Go Links: /[a-zA-Z0-9_-]+       │             │
│         │              ┌─────────────────────┘             │
│         │              │                                   │
│         │              ▼                                   │
│         │       ┌─────────────┐                           │
│         │       │ PostgreSQL  │                           │
│         │       │ (database)  │                           │
│         │       │ Port 5432   │                           │
│         │       └─────────────┘                           │
│         │                                                 │
│         ▼                                                 │
│  ┌─────────────┐                                          │
│  │   User      │                                          │
│  │   Browser   │  Production: http://go/shortname         │
│  │             │  Development: http://go.local:2080/      │
│  └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘

Request Flow for Go Links:
1. User → http://go/workday
2. nginx → /api/urls/redirect/workday
3. API → Database lookup
4. API → 302 Location: https://target-url.com
5. nginx → 302 response to user
6. User → Redirected to target URL
```

## 📦 Prerequisites

### Required Software
- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git** (for cloning the repository)

### System Requirements
- **RAM**: Minimum 2GB, Recommended 4GB
- **Storage**: Minimum 5GB free space
- **CPU**: 2+ cores recommended
- **OS**: Linux, macOS, or Windows with WSL2

### Network Requirements
- Ports 80, 5000, 8080, 5432 available
- Internet access for Docker image pulls

## 🚀 Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone https://github.com/naveen-maddipati/gourls.git
cd gourls

# Setup script permissions
chmod +x docker/init-db/01-init.sh
```

### 2. Deploy Production Environment
```bash
# Start production environment (port 80, clean URLs)
docker-compose --env-file environments/.env.production up -d --build

# Check all containers are healthy
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 3. Deploy Development Environment  
```bash
# Start development environment (port 2080, with port numbers)
docker-compose --env-file environments/.env.development up -d --build
```

### 4. Access
**Production Environment:**
- **Main Application**: http://go/ (clean URLs)
- **API Endpoints**: http://go/api/urls
- **Go Link Redirects**: http://go/shortname → automatic redirect

**Development Environment:**
- **Main Application**: http://go.local:2080/
- **Angular Direct**: http://localhost:2200
- **API Direct**: http://localhost:2165

> **Note**: Both environments run in parallel with isolated databases and different port strategies.

## ⚙️ Configuration

### Environment Files

GoUrls uses a dual-environment configuration system:

#### `environments/.env.production`
Production Docker environment with clean URLs:
```bash
# Production Settings (Clean URLs)
PROJECT_NAME=gourls
GO_DOMAIN=go                 # Production domain

# Production Ports (port 80 for clean URLs)
NGINX_PORT=80                # nginx proxy (standard HTTP)
FRONTEND_PORT=3200           # Angular container
API_PORT=3000                # .NET Core API
POSTGRES_PORT=3432           # PostgreSQL

# Frontend Build Configuration
FRONTEND_BASE_URL=/
FRONTEND_API_URL=/api
IS_PRODUCTION=true

# Database Configuration
POSTGRES_DB=gourls
POSTGRES_USER=postgres
POSTGRES_PASSWORD=gourls_secure_password
```

#### `environments/.env.development`
Development environment with port-based access:
```bash
# Development Settings (Port-based URLs)
PROJECT_NAME=gourls
GO_DOMAIN=go.local           # Development domain

# Development Ports
NGINX_PORT=2080              # nginx proxy with port
FRONTEND_PORT=2200           # Angular dev server
API_PORT=2165                # .NET Core API
POSTGRES_PORT=2431           # PostgreSQL

# Frontend Build Configuration
FRONTEND_BASE_URL=http://localhost:2165/
FRONTEND_API_URL=/api
IS_PRODUCTION=false

# Database Configuration (isolated from production)
POSTGRES_DB=gourls_dev
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password123
```

### **Port Strategy**
| Environment | Port Range | nginx | Frontend | API | Database | Domain |
|-------------|------------|-------|----------|-----|----------|---------|
| **Development** | **2000-2999** | 2080 | 2200 | 2165 | 2431 | `go.local` |
| **Production** | **3000-3999** | 80* | 3200 | 3000 | 3432 | `go` |

> **Port Range Benefits**: Dedicated ranges prevent conflicts, enable parallel environments, and provide clear separation between dev/prod

### **Zero Hardcoding System**
✅ **Zero Hardcoded Values**: All configuration driven by environment variables  
✅ **Parallel Environments**: Run both dev and prod simultaneously  
✅ **Parameterized Docker Builds**: Frontend constants generated dynamically  
✅ **Container Dependencies**: Proper health check chain (postgres → api → nginx)  
✅ **Port Strategy**: Production uses clean URLs, development uses numbered ports

### Customization Options

#### Database Configuration
```bash
# Custom database settings
POSTGRES_DB=my_gourls_db
POSTGRES_USER=gourls_user  
POSTGRES_PASSWORD=super_secure_password_2024
```

#### Port Configuration
```bash
# Custom ports (avoid conflicts)
NGINX_PORT=8080
API_PORT=5001
FRONTEND_PORT=8081
POSTGRES_PORT=5433
```

#### Production Settings
```bash
# Production optimizations
ASPNETCORE_ENVIRONMENT=Production
POSTGRES_MAX_CONNECTIONS=100
POSTGRES_SHARED_BUFFERS=256MB
```

## 🎮 Deployment Commands

### Production Environment
```bash
# Start production (clean URLs on port 80)
docker-compose --env-file environments/.env.production up -d --build

# Stop production
docker-compose --env-file environments/.env.production down

# View production logs
docker-compose --env-file environments/.env.production logs -f

# Restart production services
docker-compose --env-file environments/.env.production restart

# Check production status
docker-compose --env-file environments/.env.production ps
```

### Development Environment
```bash
# Start development (port-based URLs)
docker-compose --env-file environments/.env.development up -d --build

# Stop development
docker-compose --env-file environments/.env.development down

# View development logs
docker-compose --env-file environments/.env.development logs -f
```

### Both Environments
```bash
# Run both environments in parallel
docker-compose --env-file environments/.env.production up -d --build
docker-compose --env-file environments/.env.development up -d --build

# Production: http://go/ (port 80)
# Development: http://go.local:2080/ (port 2080)
```

### Container Management
```bash
# Check all GoUrls containers
docker ps --format "table {{.Names}}\t{{.Status}}" | grep gourls

# View specific service logs
docker logs gourls-nginx --tail=20
docker logs gourls-api --tail=20
docker logs gourls-frontend --tail=20
docker logs gourls-postgres --tail=20

# Access container shell
docker exec -it gourls-api /bin/bash
docker exec -it gourls-postgres psql -U postgres -d gourls
```

### 📊 Monitoring Commands

```bash
# View logs for all services
./deploy-gourls.sh --logs

# View logs for specific service
./deploy-gourls.sh --logs api
./deploy-gourls.sh --logs frontend
./deploy-gourls.sh --logs postgres
./deploy-gourls.sh --logs nginx

# Access container shell
./deploy-gourls.sh --shell api
./deploy-gourls.sh --shell postgres
```

### 🔄 Maintenance Commands

```bash
# Rebuild all images
./deploy-gourls.sh --build

# Update and restart services
./deploy-gourls.sh --update

# Clean up unused Docker resources
./deploy-gourls.sh --clean

# Reset everything (⚠️ destroys data)
./deploy-gourls.sh --reset
```

### 💾 Database Operations

```bash
# Access PostgreSQL shell
./deploy-gourls.sh --shell postgres

# Create database backup
./deploy-gourls.sh --backup

# Restore from backup
./deploy-gourls.sh --restore backup_file.sql
```

### 🌐 Hosts File Management

The deployment script can automatically manage your system's hosts file to enable the `go/` domain:

```bash
# Setup hosts file for 'go' domain (done automatically on --start)
./deploy-gourls.sh --setup-hosts

# Check if hosts file is properly configured
./deploy-gourls.sh --check-hosts

# Remove hosts file entry for 'go' domain
./deploy-gourls.sh --remove-hosts
```

**What this does:**
- Adds `127.0.0.1 go` to your `/etc/hosts` file
- Enables access via http://go/ instead of http://localhost/
- Creates automatic backups of your hosts file before changes
- Requires administrator privileges (will prompt for password)

**Note:** Hosts configuration happens automatically when you run `./deploy-gourls.sh --start`

### Development & Debugging
```bash
# View all logs
./deploy-gourls.sh logs

# View specific service logs
./deploy-gourls.sh logs api
./deploy-gourls.sh logs frontend
./deploy-gourls.sh logs postgres
./deploy-gourls.sh logs nginx

# Open shell in container
./deploy-gourls.sh shell api
./deploy-gourls.sh shell postgres
```

### Maintenance
```bash
# Build/rebuild images
./deploy-gourls.sh build

# Update to latest versions
./deploy-gourls.sh update

# Clean everything (destructive)
./deploy-gourls.sh clean

# Full reset (clean + rebuild)
./deploy-gourls.sh reset
```

### Database Operations
```bash
# Connect to database
./deploy-gourls.sh shell postgres

# Create backup
./deploy-gourls.sh backup

# Restore from backup
./deploy-gourls.sh restore backup_file.sql
```

## 📊 Monitoring & Maintenance

### Health Checks

All services include health checks:
- **nginx**: `http://localhost/health`
- **API**: `http://localhost:5000/api/urls`  
- **Frontend**: `http://localhost:8080/health`
- **PostgreSQL**: Internal `pg_isready` check

### Log Management
```bash
# Real-time log monitoring
./deploy-gourls.sh logs -f

# Service-specific logs
./deploy-gourls.sh logs api -f
./deploy-gourls.sh logs nginx -f
```

### Resource Monitoring
```bash
# Check resource usage
./deploy-gourls.sh status

# Docker stats
docker stats
```

### Backup Strategy
```bash
# Regular database backups
./deploy-gourls.sh backup

# Backup with timestamp
BACKUP_FILE="gourls_backup_$(date +%Y%m%d_%H%M%S).sql"
./deploy-gourls.sh backup > "$BACKUP_FILE"
```

## 🚀 Production Deployment

### Security Considerations

1. **Change Default Passwords**
   ```bash
   # Update .env.docker
   POSTGRES_PASSWORD=very_secure_production_password
   ```

2. **Use HTTPS** (recommended)
   ```bash
   # Configure SSL
   NGINX_PORT=443
   ENABLE_SSL=true
   SSL_CERT_PATH=/path/to/cert.pem
   SSL_KEY_PATH=/path/to/key.pem
   ```

3. **Firewall Configuration**
   ```bash
   # Only expose necessary ports
   # Block direct access to 5000, 8080, 5432
   # Only allow 80/443 externally
   ```

### Performance Optimization

1. **Database Tuning**
   ```bash
   # In .env.docker
   POSTGRES_MAX_CONNECTIONS=200
   POSTGRES_SHARED_BUFFERS=512MB
   POSTGRES_WORK_MEM=4MB
   ```

2. **Resource Limits**
   ```yaml
   # Add to docker-compose.yml
   deploy:
     resources:
       limits:
         memory: 512M
         cpus: '0.5'
   ```

### Scaling Options

1. **Multiple Replicas**
   ```bash
   # Scale specific services
   docker-compose up -d --scale api=3 --scale frontend=2
   ```

2. **Load Balancing**
   - nginx automatically balances across replicas
   - Database remains single instance (consider PostgreSQL clustering for high availability)

## 🔍 Troubleshooting

### Container Startup Issues

#### All Containers Don't Start with `up -d --build`
**Symptom**: Only some containers start, API/nginx missing
**Cause**: Database init script permission issue causing dependency cascade failure

**Solution**:
```bash
# Fix init script permissions
chmod +x docker/init-db/01-init.sh

# Clean restart
docker-compose --env-file environments/.env.production down --volumes
docker-compose --env-file environments/.env.production up -d --build
```

#### Go Links Return HTML Instead of Redirects
**Symptom**: `curl http://go/shortname` returns Angular HTML instead of 302 redirect
**Root Causes**: 
1. nginx upstream container names incorrect
2. Frontend making `/api/api/` requests (double API path)
3. nginx location regex not matching properly

**Solution**: Verify nginx logs and container names:
```bash
# Check nginx error logs
docker logs gourls-nginx --tail=20

# Verify container names match nginx.conf upstreams
docker ps --format "{{.Names}}" | grep gourls

# Test API endpoint directly
curl -v http://go/api/urls/redirect/shortname
```

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check port conflicts  
netstat -tulpn | grep :80
lsof -i :80

# Check container logs
docker-compose --env-file environments/.env.production logs
```

#### Database Connection Issues
```bash
# Check PostgreSQL health
docker exec gourls-postgres pg_isready -U postgres

# Access database directly
docker exec -it gourls-postgres psql -U postgres -d gourls

# Reset database volume
docker-compose --env-file environments/.env.production down --volumes
docker-compose --env-file environments/.env.production up -d postgres
```

#### Frontend API Calls Failing
**Symptom**: 404 errors for `/api/api/urls` requests
**Cause**: Frontend `Base_Url` configuration incorrect

**Solution**: Check frontend container constants:
```bash
# Verify frontend build args in docker-compose.yml
grep -A 10 "frontend:" docker-compose.yml

# Rebuild frontend with correct args
docker-compose --env-file environments/.env.production build frontend
docker-compose --env-file environments/.env.production restart frontend
```

#### nginx Redirect Issues
```bash
# Check nginx configuration syntax
docker exec gourls-nginx nginx -t

# View nginx access logs for redirect patterns
docker logs gourls-nginx | grep -E "(302|redirect)"

# Test upstream connectivity from nginx
docker exec gourls-nginx curl -v http://gourls-api:5000/api/urls
```

### Performance Issues

#### High Memory Usage
```bash
# Check container stats
docker stats

# Limit container memory
# Add memory limits to docker-compose.yml
```

#### Slow Response Times
```bash
# Check nginx access logs
./deploy-gourls.sh logs nginx

# Monitor database performance
./deploy-gourls.sh shell postgres
# Run: SELECT * FROM pg_stat_activity;
```

### Recovery Procedures

#### Complete System Recovery
```bash
# Stop everything
./deploy-gourls.sh stop

# Clean and rebuild
./deploy-gourls.sh reset

# Restore from backup
./deploy-gourls.sh restore latest_backup.sql
```

#### Partial Service Recovery
```bash
# Restart specific service
docker-compose restart api
docker-compose restart frontend
docker-compose restart nginx
```

## 📞 Support

For additional support:
1. Check the [main documentation](../documentation/README.md)
2. Review [configuration guide](../documentation/CONFIGURATION.md)
3. Create an issue on GitHub
4. Contact the development team

## 🔄 Updates & Upgrades

### Updating GoUrls
```bash
# Pull latest code
git pull origin main

# Rebuild and restart
./deploy-gourls.sh reset
```

### Updating Docker Images
```bash
# Update base images
./deploy-gourls.sh update
```

---

**Happy containerized deployment! 🐳🚀**