# 🔧 Configuration Management Guide

This guide explains how the GoUrls project manages configuration using environment files. Understanding this system will help you customize the project for your needs while maintaining security best practices.

## 📁 Configuration File Types

### 1. **`.env.defaults` (Committed to Git)** 
**Purpose:** Base configuration that the whole team shares

**Contains:**
- ✅ Port numbers (4200, 5165, 80)
- ✅ Container names and versions
- ✅ Project settings and paths
- ✅ Non-sensitive application defaults
- ❌ **No passwords or sensitive data**

**Example:**
```bash
# Project configuration
PROJECT_NAME=gourls
GO_DOMAIN=go

# Port assignments
NGINX_PORT=80
ANGULAR_PORT=4200
API_PORT=5165
POSTGRES_PORT=5431

# Container configuration
POSTGRES_CONTAINER_NAME=gourls-postgres
POSTGRES_VERSION=15
```

### 2. **`.env.local.example` (Committed to Git)**
**Purpose:** Template showing what sensitive settings you need

**Contains:**
- 🔐 **Password placeholders** with safe examples
- 💡 **Commented examples** of common overrides
- 📋 **Instructions** on how to customize
- ❌ **No real passwords**

**Example:**
```bash
# Database password - CHANGE THIS!
POSTGRES_PASSWORD=password123

# Optional overrides (uncomment as needed):
# ANGULAR_PORT=4201
# API_PORT=5166
# POSTGRES_DB=gourls_test
```

### 3. **`.env.local` (Never Committed)**
**Purpose:** Your actual sensitive settings and personal customizations

**Contains:**
- 🔐 **Real passwords and secrets**
- ⚙️ **Personal port overrides** (if you have conflicts)
- 🎯 **Machine-specific settings**
- 🔒 **Production credentials** (on servers)

**Example:**
```bash
# Required: Database password
POSTGRES_PASSWORD=my_secure_password_2024

# Optional: Personal overrides
ANGULAR_PORT=4201  # Port 4200 conflicts with my other project
API_PORT=5166      # Port 5165 in use by another service
```

### 4. **`.env.example` (Legacy)**
**Purpose:** Old-style comprehensive example file (maintained for compatibility)

**Contains:**
- 📋 **Complete example** of all possible settings
- 💡 **Detailed documentation** and comments
- 🔄 **Single-file approach** (traditional method)

## 🔄 How Configuration Loading Works

### **Loading Order (Priority: Low → High)**
```
1. .env.defaults     ← Base settings (committed to git)
   ↓
2. .env.local        ← Your overrides (ignored by git)  
   ↓
3. .env             ← Legacy support (ignored by git)
   ↓
4. Built-in defaults ← Fallback if files missing
```

### **Startup Script Logic:**
```bash
# 1. Load team defaults
source .env.defaults

# 2. Override with your local settings  
source .env.local  # (if exists)

# 3. Legacy support
source .env        # (if exists and no .env.local)

# 4. Apply built-in fallbacks for missing values
```

## 🚀 Quick Setup Guide

### **For New Developers:**

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd gourls
   ```

2. **Set up local configuration**
   ```bash
   cp .env.local.example .env.local
   ```

3. **Edit your password**
   ```bash
   # Edit .env.local
   POSTGRES_PASSWORD=your_password_here
   ```

4. **Start development**
   ```bash
   ./startup.sh --start-all
   ```

**That's it!** Everything else uses sensible team defaults.

### **For Developers with Port Conflicts:**

If you get port conflict errors, override them in your `.env.local`:

```bash
# Add to .env.local
ANGULAR_PORT=4201    # Instead of 4200
API_PORT=5166        # Instead of 5165
POSTGRES_PORT=5432   # Instead of 5431
```

### **For Production Deployment:**

Create a production `.env.local` with:

```bash
# Production settings
POSTGRES_PASSWORD=super_secure_production_password
POSTGRES_DB=gourls_production
GO_DOMAIN=your-company-short-links
NGINX_PORT=80

# Production-specific overrides
POSTGRES_HOST=prod-db-server.company.com
POSTGRES_PORT=5432
```

## 🎯 Real-World Examples

### **Example 1: Default Developer**
**Files:**
- `.env.defaults` (from git)
- `.env.local`:
  ```bash
  POSTGRES_PASSWORD=dev123
  ```

**Result:** Uses all team defaults with custom password.

### **Example 2: Developer with Conflicts**
**Files:**
- `.env.defaults` (from git)  
- `.env.local`:
  ```bash
  POSTGRES_PASSWORD=mypass456
  ANGULAR_PORT=4201     # 4200 conflicts with other project
  API_PORT=5166         # 5165 in use by other service
  ```

**Result:** Custom ports + password, everything else uses defaults.

### **Example 3: Production Server**
**Files:**
- `.env.defaults` (from git)
- `.env.local`:
  ```bash
  POSTGRES_PASSWORD=prod_secret_2024!
  POSTGRES_DB=gourls_production
  POSTGRES_HOST=db.company.com
  GO_DOMAIN=short
  ```

**Result:** Production-ready configuration with secure settings.

## 🔐 Security Model

| File | Git Tracked? | Contains Passwords? | Purpose |
|------|-------------|-------------------|---------|
| `.env.defaults` | ✅ **Yes** | ❌ **No** | Team defaults |
| `.env.local.example` | ✅ **Yes** | ❌ **No** | Template only |
| `.env.local` | ❌ **Never** | ✅ **Yes** | Your secrets |
| `.env` | ❌ **Never** | ✅ **Yes** | Legacy support |

### **Security Benefits:**

1. **🔒 Zero Risk of Password Leaks**
   - Sensitive files are in `.gitignore`
   - Only templates and defaults are committed

2. **👥 Team Consistency**  
   - Everyone gets the same base configuration
   - Reduces "works on my machine" issues

3. **🔧 Easy Customization**
   - Override only what you need to change
   - No need to maintain full config files

4. **📦 Production Ready**
   - Same system works for development and production
   - Clear separation of concerns

## 🔧 Available Configuration Variables

### **Application Settings**
- `PROJECT_NAME` - Project identifier (default: `gourls`)
- `GO_DOMAIN` - Short link domain (default: `go`)

### **Port Configuration**
- `NGINX_PORT` - Reverse proxy port (default: `80`)
- `ANGULAR_PORT` - Angular dev server (default: `4200`)
- `API_PORT` - .NET API server (default: `5165`)  
- `POSTGRES_PORT` - Database host port (default: `5431`)

### **Database Settings**
- `POSTGRES_HOST` - Database server (default: `127.0.0.1`)
- `POSTGRES_DB` - Database name (default: `gourls`)
- `POSTGRES_USER` - Database user (default: `postgres`)
- `POSTGRES_PASSWORD` - Database password (**required in `.env.local`**)
- `POSTGRES_CONTAINER_NAME` - Docker container name (default: `gourls-postgres`)
- `POSTGRES_VERSION` - PostgreSQL version (default: `15`)

### **Development Paths**
- `LOGS_DIR` - Log file directory (default: `logs`)
- `API_PROJECT_DIR` - .NET project folder (default: `GoUrlsApi`)
- `ANGULAR_PROJECT_DIR` - Angular project folder (default: `go-urls-app`)
- `NGINX_CONFIG_FILE` - nginx config file (default: `nginx-go-proxy.conf`)

### **System Requirements**
- `NODE_VERSION_REQUIRED` - Required Node.js version (default: `22.21.1`)

## 🌐 Domain Configuration & Hosts File Setup

### **GO_DOMAIN Explained**
The `GO_DOMAIN` variable determines what short domain your GoUrls application uses:

- **Default**: `go` → Access via http://go/
- **Custom**: `links` → Access via http://links/  
- **Corporate**: `company` → Access via http://company/

### **Automatic Hosts File Management**
Both development scripts automatically manage your system's hosts file:

**Development Environment (`startup.sh`):**
```bash
./startup.sh --start-all     # Automatically configures hosts
./startup.sh --setup-hosts   # Manual hosts setup
./startup.sh --check-hosts   # Verify configuration
./startup.sh --remove-hosts  # Remove hosts entry
```

**Docker Deployment (`deploy-gourls.sh`):**
```bash
./deploy-gourls.sh --start        # Automatically configures hosts
./deploy-gourls.sh --setup-hosts  # Manual hosts setup
./deploy-gourls.sh --check-hosts  # Verify configuration
./deploy-gourls.sh --remove-hosts # Remove hosts entry
```

### **What Happens During Setup**
1. **Backup Creation**: Automatic `/etc/hosts` backup
2. **Entry Addition**: Adds `127.0.0.1 go` (or your custom domain)
3. **Permission Prompt**: Requests sudo access if needed
4. **Verification**: Confirms successful configuration

### **Manual Hosts Configuration**
If you prefer manual setup, add this line to `/etc/hosts`:
```bash
127.0.0.1   go
```

**On macOS/Linux:**
```bash
sudo echo "127.0.0.1   go" >> /etc/hosts
```

**On Windows:**
Edit `C:\Windows\System32\drivers\etc\hosts` as Administrator

## 🐛 Troubleshooting

### **"No .env.local found" Warning**
```bash
⚠️  No configuration files found.
   Create .env.local from .env.local.example for local settings
```

**Solution:**
```bash
cp .env.local.example .env.local
# Edit .env.local and set POSTGRES_PASSWORD
```

### **Port Conflict Errors**
```bash
Error: Port 4200 is already in use
```

**Solution:** Override in `.env.local`:
```bash
echo "ANGULAR_PORT=4201" >> .env.local
```

### **Database Connection Fails**
Check your `.env.local` has the correct password:
```bash
# .env.local
POSTGRES_PASSWORD=your_actual_password
```

### **nginx Won't Start**
Port 80 requires admin privileges:
```bash
# Either run with sudo (not recommended for development)
sudo ./startup.sh --start-all

# Or override to use non-privileged port
echo "NGINX_PORT=8080" >> .env.local
```

## 📚 Migration from Old System

### **If you have an existing `.env` file:**

The system automatically detects and uses legacy `.env` files. To migrate:

1. **Backup your current settings:**
   ```bash
   cp .env .env.backup
   ```

2. **Create new structure:**
   ```bash
   cp .env.local.example .env.local
   # Copy sensitive settings from .env.backup to .env.local
   ```

3. **Remove old file:**
   ```bash
   rm .env .env.backup
   ```

The startup script will automatically use the new structure!

## 🎉 Benefits of This System

✅ **Security** - Passwords never committed to git  
✅ **Convenience** - Sane defaults for everyone  
✅ **Flexibility** - Easy personal customization  
✅ **Onboarding** - New devs get working setup instantly  
✅ **Production Ready** - Same system scales to production  
✅ **Team Consistency** - Eliminates configuration drift  
✅ **Documentation** - Self-documenting with examples  

This configuration system follows modern DevOps best practices and makes the GoUrls project both secure and easy to work with! 🚀