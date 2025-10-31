# 🚀 GoUrls Development Environment - Simple Management

## 📚 Documentation

For detailed documentation, see the [`docs/`](./docs/) folder:
- **[📖 Configuration Guide](./docs/CONFIGURATION.md)** - Complete configuration management
- **[📖 Documentation Index](./docs/README.md)** - All available documentation

## 🎯 One Script, All Commands!

```bash
./startup.sh --start-all
```

**That's it! One script replaces all the complexity.**

✅ **Cleaned up project** - removed 7+ old scripts  
✅ **Single entry point** - no more confusion  
✅ **Simple commands** - easy to remember  

## 📋 Available Commands

| Command | Purpose |
|---------|---------|
| `./startup.sh --start-all` | 🚀 Start all services |
| `./startup.sh --stop-all` | 🛑 Stop all services |
| `./startup.sh --restart` | 🔄 Restart all services |
| `./startup.sh --status` | 🔍 Check status of all services |
| `./startup.sh --restart-service <service>` | 🔄 Restart specific service |
| `./startup.sh --help` | ❓ Show help and examples |

## 🎮 Common Usage

### Starting Development
```bash
# Start everything
./startup.sh --start-all

# Check if everything is working
./startup.sh --status
```

### During Development
```bash
# Restart just Angular after making changes
./startup.sh --restart-service angular

# Restart just the API
./startup.sh --restart-service api

# Restart nginx if proxy issues
./startup.sh --restart-service nginx

# Restart database
./startup.sh --restart-service postgres
```

### Quick Restart
```bash
# Restart everything (stop + start)
./startup.sh --restart
```

### Ending Development
```bash
# Stop everything
./startup.sh --stop-all
```

## 🌐 Access URLs

After running `./startup.sh --start-all`, you can access:

- **Main App**: http://go
- **Angular Direct**: http://localhost:4200
- **API Direct**: http://localhost:5165

## 🔧 Troubleshooting

### If something isn't working:

1. **Check status**:
   ```bash
   ./startup.sh --status
   ```

2. **View logs**:
   ```bash
   tail -f logs/angular.log
   tail -f logs/api.log
   ```

3. **Restart specific service**:
   ```bash
   ./startup.sh --restart-service angular
   ./startup.sh --restart-service api
   ./startup.sh --restart-service nginx
   ./startup.sh --restart-service postgres
   ```

4. **Full restart**:
   ```bash
   ./startup.sh --restart
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
**[📖 docs/CONFIGURATION.md](./docs/CONFIGURATION.md)**

This guide covers:
- 🔧 How different `.env` files work together
- 🛡️ Security best practices  
- 🎯 Real-world configuration examples
- 🐛 Troubleshooting configuration issues
- 🚀 Production deployment settings

**No more confusion - just one script with clear commands!** 🚀