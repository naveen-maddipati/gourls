# 🚀 GoUrls Development Environment - Simple Management

## 📚 Documentation

For detailed documentation, see the [`documentation/`](./documentation/) folder:
## 📋 Quick Links

- **[Development Setup](./documentation/CONFIGURATION.md)** - Environment configuration and setup
- **[Docker Deployment](./documentation/DEPLOY-GOURLS.md)** - Complete containerized deployment guide
- **[Documentation Index](./documentation/README.md)** - All project documentation

## 🎯 One Script, All Commands!

```bash
./scripts/startup.sh --start-all
```

**That's it! One script replaces all the complexity.**

✅ **Cleaned up project** - removed 7+ old scripts  
✅ **Single entry point** - no more confusion  
✅ **Simple commands** - easy to remember  

## 📋 Available Commands

| Command | Purpose |
|---------|---------|
| `./scripts/startup.sh --start-all` | 🚀 Start all services |
| `./scripts/startup.sh --stop-all` | 🛑 Stop all services |
| `./scripts/startup.sh --restart` | 🔄 Restart all services |
| `./scripts/startup.sh --status` | 🔍 Check status of all services |
| `./scripts/startup.sh --restart-service <service>` | 🔄 Restart specific service |
| `./scripts/startup.sh --help` | ❓ Show help and examples |

## 🎮 Common Usage

### Starting Development
```bash
# Start everything (includes automatic hosts setup for 'go' domain)
./scripts/startup.sh --start-all

# Check if everything is working
./scripts/startup.sh --status
```

> **Note**: The first run will prompt for your password to configure the hosts file, enabling access via http://go/

### During Development
```bash
# Restart just Angular after making changes
./scripts/startup.sh --restart-service angular

# Restart just the API
./scripts/startup.sh --restart-service api

# Restart nginx if proxy issues
./scripts/startup.sh --restart-service nginx

# Restart database
./scripts/startup.sh --restart-service postgres
```

### Quick Restart
```bash
# Restart everything (stop + start)
./scripts/startup.sh --restart
```

### Ending Development
```bash
# Stop everything
./scripts/startup.sh --stop-all
```

## 🌐 Access URLs

After running `./scripts/startup.sh --start-all`, you can access:

- **Main App**: http://go
- **Angular Direct**: http://localhost:4200
- **API Direct**: http://localhost:5165

## 🔧 Troubleshooting

### If something isn't working:

1. **Check status**:
   ```bash
   ./scripts/startup.sh --status
   ```

2. **View logs**:
   ```bash
   tail -f logs/angular.log
   tail -f logs/api.log
   ```

3. **Restart specific service**:
   ```bash
   ./scripts/startup.sh --restart-service angular
   ./scripts/startup.sh --restart-service api
   ./scripts/startup.sh --restart-service nginx
   ./scripts/startup.sh --restart-service postgres
   ```

4. **Full restart**:
   ```bash
   ./scripts/startup.sh --restart
   ```

## ✨ Features

✅ **Single script for everything**
✅ **Clear color-coded output**
✅ **Intelligent service detection**
✅ **Automatic error handling and retry logic**
✅ **Process management with PID files**
✅ **Comprehensive logging**
✅ **Node.js version management**
✅ **Docker container management**

## 📁 What Gets Created

- `logs/` - Log files for all services
- `logs/angular.pid` - Angular process ID
- `logs/api.pid` - API process ID
- `logs/angular.log` - Angular console output
- `logs/api.log` - API console output

## 🎯 Example Workflow

```bash
# Day 1: Start development
./startup.sh --start-all

# Check everything is working
./startup.sh --status

# Made changes to Angular? Restart it
./startup.sh --restart-service angular

# Made changes to API? Restart it
./startup.sh --restart-service api

# End of day: Stop everything
./startup.sh --stop-all

# Day 2: Quick start
./startup.sh --start-all
```

## ⚙️ Configuration System

GoUrls uses a layered configuration system that separates safe defaults from sensitive data.

### 🚀 Quick Setup

1. **Create your local configuration:**
   ```bash
   cp .env.local.example .env.local
   ```

2. **Set your database password:**
   ```bash
   # Edit .env.local
   POSTGRES_PASSWORD=your_secure_password
   ```

3. **Start developing:**
   ```bash
   ./startup.sh --start-all
   ```

**That's it!** The system automatically loads defaults + your overrides.

### 📖 Detailed Configuration Guide

For comprehensive information about configuration management, see:  
**[📖 documentation/CONFIGURATION.md](./documentation/CONFIGURATION.md)**

This guide covers:
- 🔧 How different `.env` files work together
- 🛡️ Security best practices  
- 🎯 Real-world configuration examples
- 🐛 Troubleshooting configuration issues
- 🚀 Production deployment settings

**No more confusion - just one script with clear commands!** 🚀