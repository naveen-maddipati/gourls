# GoUrls Local Development with go/ URL Masking

This setup allows you to access your GoUrls application using `go` instead of `localhost:4200`, making your short URLs work as `http://go/shortname`.

## Setup Instructions

### 1. One-time Setup
Run the setup script to install nginx and configure your system:

```bash
./setup-dev.sh
```

This will:
- Install nginx (if not already installed)
- Add `go` to your `/etc/hosts` file
- Copy nginx configuration
- Test the configuration

### 2. Daily Development Workflow

#### Start Development Environment
```bash
# Start nginx proxy
./start-dev.sh

# In another terminal, start Angular dev server
cd go-urls-app
ng serve
```

#### Access Your Application
- **Main App**: http://go
- **Short URLs**: http://go/shortname (where `shortname` is your registered short URL)
- **Admin Pages**: http://go/search, http://go/create

#### Stop Development Environment
```bash
# Stop nginx
./stop-dev.sh

# Stop Angular dev server (Ctrl+C in the ng serve terminal)
```

## How It Works

1. **nginx** acts as a reverse proxy listening on port 80
2. **go** domain points to localhost via `/etc/hosts`
3. All requests to `go` are forwarded to your Angular dev server on `localhost:4200`
4. Your Go Links routing in Angular handles the short URL redirection

## Troubleshooting

### nginx won't start
```bash
# Check if something is using port 80
sudo lsof -i :80

# Test nginx configuration
sudo nginx -t

# View nginx logs
tail -f /usr/local/var/log/nginx/error.log
```

### Can't access go
```bash
# Verify hosts file entry
cat /etc/hosts | grep "127.0.0.1   go$"

# Test DNS resolution
nslookup go
```

### Reset Everything
```bash
# Stop nginx
sudo nginx -s stop

# Remove hosts entry
sudo sed -i '' '/127.0.0.1   go$/d' /etc/hosts

# Remove nginx config
sudo rm /usr/local/etc/nginx/servers/nginx-go-proxy.conf

# Re-run setup
./setup-dev.sh
```

## Benefits

- ✅ Realistic URL structure for testing
- ✅ Easy sharing with team members
- ✅ Better mimics production environment
- ✅ Works with all existing Angular routing
- ✅ No code changes required