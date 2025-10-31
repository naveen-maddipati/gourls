#!/bin/bash

# 🚀 GoUrls Environment Manager
# Manages both local development and container production environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load environment variables function
load_env() {
    local env_file="$1"
    if [[ -f "$env_file" ]]; then
        echo "Loading environment from: $env_file"
        set -a
        source "$env_file"
        set +a
    else
        echo "Warning: Environment file not found: $env_file"
    fi
}

# Default environment file (can be overridden)
ENV_FILE="${PROJECT_ROOT}/environments/.env.development"

# Load environment variables
load_env "$ENV_FILE"

# Set defaults for critical variables from development environment
PROJECT_NAME=${PROJECT_NAME:-gourls}
GO_DOMAIN=${GO_DOMAIN:-gourls.local}
DEV_DOMAIN=${GO_DOMAIN}  # Use GO_DOMAIN from loaded env
ANGULAR_PORT=${ANGULAR_PORT:-4200}
API_PORT=${API_PORT:-5165}
POSTGRES_PORT=${POSTGRES_PORT:-5431}
NGINX_PORT=${NGINX_PORT:-8888}

# Production environment defaults (loaded when needed)
PROD_GO_DOMAIN="go"
PROD_NGINX_PORT=80
FRONTEND_PORT=8080
PROD_API_PORT=5000
PROD_DB_PORT=5432

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging functions
log_header() {
    echo -e "\n${PURPLE}$1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check which environments are running
check_environments() {
    log_header "🔍 Environment Status Check"
    
    # Check local development
    local dev_running=false
    if curl -s "http://${DEV_DOMAIN}/health" > /dev/null 2>&1; then
        dev_running=true
        log_success "Local Development (${DEV_DOMAIN}) is running"
    else
        log_warning "Local Development (${DEV_DOMAIN}) is not running"
    fi
    
    # Check container production
    local prod_running=false
    if curl -s "http://${PROD_GO_DOMAIN}/health" > /dev/null 2>&1; then
        prod_running=true
        log_success "Container Production (${PROD_GO_DOMAIN}) is running"
    else
        log_warning "Container Production (${PROD_GO_DOMAIN}) is not running"
    fi
    
    # Check port conflicts
    echo ""
    log_info "Port Usage:"
    echo "  Development:  nginx(${NGINX_PORT}), angular(${ANGULAR_PORT}), api(${API_PORT}), db(${POSTGRES_PORT})"
    echo "  Production:   nginx(${PROD_NGINX_PORT}), frontend(${FRONTEND_PORT}), api(${PROD_API_PORT}), db(${PROD_DB_PORT})"
    
    # Check hosts file
    echo ""
    log_info "Hosts Configuration:"
    if grep -q "127.0.0.1[[:space:]]*gourls\.local" /etc/hosts 2>/dev/null; then
        log_success "gourls.local is configured"
    else
        log_warning "gourls.local is not configured"
    fi
    
    if grep -q "127.0.0.1[[:space:]]*go" /etc/hosts 2>/dev/null; then
        log_success "go is configured"
    else
        log_warning "go is not configured"
    fi
}

# Setup hosts file for both domains
setup_hosts() {
    log_header "🌐 Setting up Hosts File"
    
    # Check if entries exist
    local go_exists=$(grep -c "127.0.0.1[[:space:]]*go$" /etc/hosts 2>/dev/null || echo "0")
    local gourls_local_exists=$(grep -c "127.0.0.1[[:space:]]*gourls\.local" /etc/hosts 2>/dev/null || echo "0")
    
    if [[ "$go_exists" -gt 0 && "$gourls_local_exists" -gt 0 ]]; then
        log_success "Both domains are already configured"
        return 0
    fi
    
    log_info "Setting up hosts file for both environments..."
    
    # Create backup
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Add go domain if missing
    if [[ "$go_exists" -eq 0 ]]; then
        echo "127.0.0.1   go" | sudo tee -a /etc/hosts > /dev/null
        log_success "Added 'go' domain for container production"
    fi
    
    # Add gourls.local domain if missing
    if [[ "$gourls_local_exists" -eq 0 ]]; then
        echo "127.0.0.1   gourls.local" | sudo tee -a /etc/hosts > /dev/null
        log_success "Added 'gourls.local' domain for local development"
    fi
    
    log_success "Hosts file configured for both environments"
}

# Start local development environment
start_development() {
    log_header "🚀 Starting Local Development Environment (go.dev)"
    
    # Setup hosts first
    setup_hosts
    
    # Start development environment
    "$SCRIPT_DIR/startup.sh" --start-all
    
    echo ""
    log_success "Development environment started!"
    echo "  🔗 Access via: http://gourls.local/"
    echo "  🔗 Direct Angular: http://localhost:${ANGULAR_PORT}/"
    echo "  🔗 API: http://localhost:${API_PORT}/"
}

# Start container production environment
start_production() {
    log_header "🐳 Starting Container Production Environment (go)"
    
    # Setup hosts first
    setup_hosts
    
    # Start container environment
    "$SCRIPT_DIR/deploy-gourls.sh" --start
    
    echo ""
    log_success "Container production environment started!"
    echo "  🔗 Access via: http://go/"
    echo "  🔗 Direct Frontend: http://localhost:${FRONTEND_PORT}/"
    echo "  🔗 API: http://localhost:${PROD_API_PORT}/"
}

# Start both environments
start_both() {
    log_header "🚀🐳 Starting Both Environments"
    
    setup_hosts
    
    log_info "Starting container production first..."
    "$SCRIPT_DIR/deploy-gourls.sh" --start
    
    sleep 5
    
    log_info "Starting local development..."
    "$SCRIPT_DIR/startup.sh" --start-all
    
    echo ""
    log_success "Both environments are running!"
    echo ""
    echo "  🐳 Container Production: http://go/"
    echo "  🚀 Local Development:   http://gourls.local/"
    echo ""
    echo "  Use different environments for different purposes:"
    echo "  - http://go/           → Test production-like behavior"
    echo "  - http://gourls.local/ → Active development and testing"
}

# Stop environments
stop_development() {
    log_info "Stopping local development environment..."
    "$SCRIPT_DIR/startup.sh" --stop-all
}

stop_production() {
    log_info "Stopping container production environment..."
    "$SCRIPT_DIR/deploy-gourls.sh" --stop
}

stop_both() {
    log_header "🛑 Stopping Both Environments"
    stop_development
    stop_production
    log_success "Both environments stopped"
}

# Show help
show_help() {
    cat << EOF
🚀🐳 GoUrls Environment Manager

This script manages both local development and container production environments
that can run simultaneously without conflicts.

USAGE:
    ./env-manager.sh [COMMAND]

COMMANDS:
    --start-dev         🚀 Start local development (${DEV_DOMAIN}:${NGINX_PORT})
    --start-prod        🐳 Start container production (go:80)  
    --start-both        🚀🐳 Start both environments
    --stop-dev          🛑 Stop local development
    --stop-prod         🛑 Stop container production
    --stop-both         🛑 Stop both environments
    --status            🔍 Check status of both environments
    --setup-hosts       🌐 Setup hosts file for both domains
    --help              ❓ Show this help

ENVIRONMENTS:
      Domain: http://${DEV_DOMAIN}/
      Ports:  nginx(${NGINX_PORT}), angular(${ANGULAR_PORT}), api(${API_PORT}), db(${POSTGRES_PORT})
      Use for: Active development, debugging, hot reload
      
    Container Production:
      Domain: http://${PROD_GO_DOMAIN}/  
      Ports:  nginx(${PROD_NGINX_PORT}), frontend(${FRONTEND_PORT}), api(${PROD_API_PORT}), db(${PROD_DB_PORT})
      Use for: Production testing, final validation

EXAMPLES:
    ./env-manager.sh --start-both       # Start both environments
    ./env-manager.sh --status           # Check what's running
    ./env-manager.sh --start-dev        # Just development
    ./env-manager.sh --setup-hosts      # Configure domains

EOF
}

# Main command processing
case "${1:-help}" in
    --start-dev|--start-development)
        start_development
        ;;
    --start-prod|--start-production)
        start_production
        ;;
    --start-both|--start-all)
        start_both
        ;;
    --stop-dev|--stop-development)
        stop_development
        ;;
    --stop-prod|--stop-production)
        stop_production
        ;;
    --stop-both|--stop-all)
        stop_both
        ;;
    --status)
        check_environments
        ;;
    --setup-hosts)
        setup_hosts
        ;;
    --help|help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use './env-manager.sh --help' to see available commands."
        exit 1
        ;;
esac