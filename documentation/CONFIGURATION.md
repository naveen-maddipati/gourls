# 🔧 Configuration Management Guide

This guide explains how the GoUrls project manages configuration using environment files for both development and production Docker environments.

## 📁 Environment Configuration Systems

GoUrls uses two distinct configuration systems:

### 1. **Development Environment** (Local Process-based)
Uses the layered `.env` file system for local development:
- `.env.defaults` (committed) - Team shared defaults
- `.env.local` (ignored) - Your personal overrides and secrets
- Legacy `.env` support for backward compatibility

### 2. **Production Environment** (Docker Container-based)  
Uses dedicated environment files for containerized deployment:
- `environments/.env.production` - Production Docker configuration
- `environments/.env.development` - Development Docker configuration

## � Docker Environment Files

### **`environments/.env.production`**
**Purpose:** Production containerized environment with clean URLs

**Key Features:**
- ✅ **Clean URLs**: Uses port 80 for `http://go/` access
- ✅ **Zero Hardcoding**: All values parameterized
- ✅ **Production Database**: Isolated `gourls` database
- ✅ **Container Orchestration**: Proper dependency chains

**Example:**
```bash
# Production Settings
PROJECT_NAME=gourls
GO_DOMAIN=go

# Production Ports (Clean URLs)
NGINX_PORT=80                 # Standard HTTP port
FRONTEND_PORT=3200            # Angular container
API_PORT=3000                 # .NET Core API
POSTGRES_PORT=3432            # PostgreSQL

# Frontend Build Configuration (No Hardcoding)
FRONTEND_BASE_URL=/           # Dynamic build args
FRONTEND_API_URL=/api
IS_PRODUCTION=true

# Database Configuration
POSTGRES_DB=gourls
POSTGRES_USER=postgres
POSTGRES_PASSWORD=gourls_secure_password

# Container Names (Parameterized)
API_CONTAINER=gourls-api
FRONTEND_CONTAINER=gourls-frontend
NGINX_CONTAINER=gourls-nginx
POSTGRES_CONTAINER=gourls-postgres
```

### **`environments/.env.development`**  
**Purpose:** Development containerized environment with port-based URLs

**Key Features:**
- ✅ **Port-based URLs**: Uses port 2080 for `http://go.local:2080/`
- ✅ **Parallel Operation**: Runs alongside production without conflicts
- ✅ **Development Database**: Isolated `gourls_dev` database
- ✅ **Hot Reload**: Supports development workflow

**Example:**
```bash
# Development Settings  
PROJECT_NAME=gourls
GO_DOMAIN=go.local

# Development Ports (With Port Numbers)
NGINX_PORT=2080               # Development with port
FRONTEND_PORT=2200            # Angular container  
API_PORT=2165                 # .NET Core API
POSTGRES_PORT=2431            # PostgreSQL

# Frontend Build Configuration
FRONTEND_BASE_URL=http://localhost:2165/
FRONTEND_API_URL=/api
IS_PRODUCTION=false

# Database Configuration (Isolated)
POSTGRES_DB=gourls_dev        # Separate dev database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password123
```

## 🚀 Usage Examples

### **Production Deployment**
```bash
# Start production (port 80, clean URLs)
docker-compose --env-file environments/.env.production up -d --build

# Access: http://go/
# API: http://go/api/urls
# Go Links: http://go/shortname → 302 redirect
```

### **Development Deployment**
```bash
# Start development (port 2080, port-based)
docker-compose --env-file environments/.env.development up -d --build

# Access: http://go.local:2080/
# API: http://localhost:2165/api/urls
```

### **Parallel Environments**
```bash
# Run both simultaneously
docker-compose --env-file environments/.env.production up -d --build
docker-compose --env-file environments/.env.development up -d --build

# Production: http://go/
# Development: http://go.local:2080/
```

## 🔧 Key Configuration Variables

### **Port Range Strategy**
GoUrls uses dedicated port ranges to avoid conflicts between environments and with other services:

| Environment | Port Range | nginx | Frontend | API | Database | Domain |
|-------------|------------|-------|----------|-----|----------|---------|
| **Development** | **2000-2999** | 2080 | 2200 | 2165 | 2431 | `go.local` |
| **Production** | **3000-3999** | 80* | 3200 | 3000 | 3432 | `go` |

> **Note**: Production nginx uses port 80 for clean URLs, but internal container ports follow the 3000+ range

### **Port Range Benefits:**
✅ **Conflict Avoidance**: Dedicated ranges prevent port collisions  
✅ **Clear Separation**: Easy to identify environment by port number  
✅ **Scalability**: Room for additional services within each range  
✅ **Predictable**: Consistent numbering pattern for troubleshooting  

### **Port Allocation Rules:**
- **2xxx ports**: Development environment (local processes + containers)
- **3xxx ports**: Production environment (Docker containers)
- **Reserved ranges**: 2000-2099 and 3000-3099 for future expansion
- **Service ports**: Allocated in 100s (nginx: x080, frontend: x200, API: x1xx, DB: x4xx)

### **Zero Hardcoding System**
All previously hardcoded values are now parameterized:

**Frontend Docker Build Args:**
- `FRONTEND_BASE_URL` - Dynamic API base URL generation
- `FRONTEND_API_URL` - API endpoint configuration  
- `IS_PRODUCTION` - Environment-specific build flags
- `GO_DOMAIN` - Dynamic domain configuration

**Container Configuration:**
- All container names use variables: `${API_CONTAINER}`
- All ports use variables: `${NGINX_PORT}:${FRONTEND_INTERNAL_PORT}`
- All network names use variables: `${NETWORK_NAME}`
- All restart policies use variables: `${RESTART_POLICY}`

### **Database Isolation**
- **Production**: `gourls` database on port 3432
- **Development**: `gourls_dev` database on port 2431
- **Parallel Operation**: No data conflicts between environments

## 🎯 Migration from Legacy System

### **If you have old `.env.docker` files:**
The new system replaces single-file Docker configuration:

```bash
# Old way (deprecated)
cp .env.docker.example .env.docker
docker-compose up -d

# New way (current)
# No copying needed - use environment files directly
docker-compose --env-file environments/.env.production up -d --build
```

### **Benefits of New System:**
✅ **Parallel Environments**: Run dev/prod simultaneously  
✅ **Zero Hardcoding**: Complete parameterization  
✅ **Clear Separation**: Production vs development concerns  
✅ **Container Dependencies**: Proper health check chains  
✅ **Dynamic Builds**: Frontend constants generated from environment  

## 🔐 Security & Best Practices

### **Production Security:**
```bash
# Change default passwords
POSTGRES_PASSWORD=super_secure_production_password_2024

# Use strong container names
API_CONTAINER=company-gourls-api-prod
```

### **Development Flexibility:**
```bash
# Override ports if conflicts exist
NGINX_PORT=8080     # If port 2080 conflicts
API_PORT=5166       # If port 2165 conflicts
```

### **Environment Isolation:**
- Each environment has its own database
- Different container names prevent conflicts
- Separate port ranges avoid collisions
- Independent configuration files

This dual-environment system provides maximum flexibility while maintaining security and enabling both development and production workflows to coexist seamlessly! 🚀

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