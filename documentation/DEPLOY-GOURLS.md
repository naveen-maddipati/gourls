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
│  │   Port 80   │    │  Port 8080  │    │  Port 5000  │     │
│  └─────────────┘    └─────────────┘    └─────┬───────┘     │
│         │                                     │             │
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
│  │   Host      │  http://localhost                       │
│  │   Port 80   │  http://go (if configured)              │
│  └─────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
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

# Make deployment script executable
chmod +x deploy-gourls.sh

# Copy environment template (optional)
cp .env.docker.example .env.docker
```

### 2. Deploy
```bash
# Start the complete application (includes automatic hosts setup)
./deploy-gourls.sh --start

# Check status
./deploy-gourls.sh --status
```

### 3. Access
- **Go Domain**: http://go/ (automatically configured)
- **Main Application**: http://localhost
- **API Documentation**: http://localhost:5000/api/urls
- **Frontend Direct**: http://localhost:8080

> **Note**: The `--start` command automatically configures your hosts file for the `go` domain. You may be prompted for your password to modify `/etc/hosts`.

## ⚙️ Configuration

### Environment Files

#### `.env.docker`
Main configuration file for Docker deployment:
```bash
# Port configuration
NGINX_PORT=80
API_PORT=5000
FRONTEND_PORT=8080
POSTGRES_PORT=5432

# Database configuration  
POSTGRES_DB=gourls
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password

# Application environment
ASPNETCORE_ENVIRONMENT=Production
```

#### `.env.docker.example`
Template file showing all available configuration options.

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

### Basic Operations
```bash
```bash
# Start services
./deploy-gourls.sh --start

# Stop services
./deploy-gourls.sh --stop

# Restart services
./deploy-gourls.sh --restart

# Check status
./deploy-gourls.sh --status
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

### Common Issues

#### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check port conflicts
netstat -tulpn | grep :80
lsof -i :80

# Check logs for errors
./deploy-gourls.sh logs
```

#### Database Connection Issues
```bash
# Check PostgreSQL health
./deploy-gourls.sh shell postgres
psql -U postgres -d gourls -c "SELECT version();"

# Reset database
./deploy-gourls.sh stop
docker volume rm gourls_postgres_data
./deploy-gourls.sh start
```

#### Frontend Not Loading
```bash
# Check nginx configuration
./deploy-gourls.sh logs nginx

# Test direct frontend access
curl http://localhost:8080

# Rebuild frontend
./deploy-gourls.sh build
```

#### API Errors
```bash
# Check API logs
./deploy-gourls.sh logs api

# Check database connectivity from API
./deploy-gourls.sh shell api
curl http://localhost:5000/api/urls
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