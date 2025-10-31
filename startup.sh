#!/bin/bash

# GoUrls Development Environment Manager
# Usage: ./startup.sh [--start-all|--stop-all|--restart|--status|--restart-service <service>|--help]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment configuration
load_env_config() {
    local defaults_file="$SCRIPT_DIR/.env.defaults"
    local local_file="$SCRIPT_DIR/.env.local"
    local legacy_env_file="$SCRIPT_DIR/.env"
    
    # Load defaults first (non-sensitive, committed to git)
    if [[ -f "$defaults_file" ]]; then
        echo "🔧 Loading default configuration from .env.defaults..."
        set -a  # Automatically export all variables
        source "$defaults_file"
        set +a  # Stop auto-exporting
    fi
    
    # Load local overrides (sensitive data, not committed)
    if [[ -f "$local_file" ]]; then
        echo "🔧 Loading local overrides from .env.local..."
        set -a  # Automatically export all variables
        source "$local_file"
        set +a  # Stop auto-exporting
    elif [[ -f "$legacy_env_file" ]]; then
        echo "🔧 Loading configuration from legacy .env file..."
        echo "   💡 Consider migrating to .env.defaults + .env.local structure"
        set -a  # Automatically export all variables
        source "$legacy_env_file"
        set +a  # Stop auto-exporting
    else
        echo "⚠️  No configuration files found."
        echo "   Create .env.local from .env.local.example for local settings"
    fi
    
    # Set default values for any missing variables
    PROJECT_NAME=${PROJECT_NAME:-gourls}
    GO_DOMAIN=${GO_DOMAIN:-go}
    NGINX_PORT=${NGINX_PORT:-80}
    ANGULAR_PORT=${ANGULAR_PORT:-4200}
    API_PORT=${API_PORT:-5165}
    POSTGRES_PORT=${POSTGRES_PORT:-5431}
    POSTGRES_HOST=${POSTGRES_HOST:-127.0.0.1}
    POSTGRES_DB=${POSTGRES_DB:-gourls}
    POSTGRES_USER=${POSTGRES_USER:-postgres}
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password123}
    POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME:-gourls-postgres}
    POSTGRES_VERSION=${POSTGRES_VERSION:-15}
    API_PROJECT_DIR=${API_PROJECT_DIR:-GoUrlsApi}
    ANGULAR_PROJECT_DIR=${ANGULAR_PROJECT_DIR:-go-urls-app}
    NODE_VERSION_REQUIRED=${NODE_VERSION_REQUIRED:-22.21.1}
    NGINX_CONFIG_FILE=${NGINX_CONFIG_FILE:-nginx-go-proxy.conf}
    
    # Set computed values
    LOGS_DIR="${LOGS_DIR:-logs}"
    # Ensure LOGS_DIR is absolute
    if [[ ! "$LOGS_DIR" = /* ]]; then
        LOGS_DIR="$SCRIPT_DIR/$LOGS_DIR"
    fi
    ANGULAR_URL="http://localhost:${ANGULAR_PORT}"
    API_URL="http://localhost:${API_PORT}"
    API_HEALTH_URL="http://localhost:${API_PORT}/api/urls"
    GO_URL="http://${GO_DOMAIN}"
    DB_CONNECTION_STRING="Host=${POSTGRES_HOST};Port=${POSTGRES_PORT};Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD}"
}

# Load configuration first
load_env_config

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Create logs directory
mkdir -p "$LOGS_DIR"

# Utility functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_header() {
    echo -e "\n${PURPLE}$1${NC}"
    echo "$(echo "$1" | sed 's/./=/g')"
}

# Function to check if a service is running
check_service() {
    local service_name=$1
    local check_command=$2
    
    if eval $check_command > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if eval $check_command > /dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        echo "   Attempt $attempt/$max_attempts - waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Function to generate nginx config from template
generate_nginx_config() {
    local template_file="$SCRIPT_DIR/nginx-go-proxy.conf.template"
    local output_file="$SCRIPT_DIR/$NGINX_CONFIG_FILE"
    
    if [[ -f "$template_file" ]]; then
        log_info "Generating nginx config from template..."
        
        # Use sed to replace template variables with actual values
        sed -e "s|{{NGINX_PORT}}|$NGINX_PORT|g" \
            -e "s|{{GO_DOMAIN}}|$GO_DOMAIN|g" \
            -e "s|{{ANGULAR_URL}}|$ANGULAR_URL|g" \
            -e "s|{{ANGULAR_PORT}}|$ANGULAR_PORT|g" \
            -e "s|{{API_URL}}|$API_URL|g" \
            "$template_file" > "$output_file"
        
        log_success "nginx config generated: $output_file"
    else
        log_info "No nginx template found, using existing config file"
    fi
}

# Function to stop service by PID file
stop_service_by_pid() {
    local service_name=$1
    local pid_file=$2
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            log_info "Stopping $service_name (PID: $pid)..."
            kill $pid
            sleep 2
            if ps -p $pid > /dev/null 2>&1; then
                log_info "Force killing $service_name..."
                kill -9 $pid
            fi
            rm -f "$pid_file"
            log_success "$service_name stopped"
        else
            log_success "$service_name was not running"
            rm -f "$pid_file"
        fi
    else
        log_success "$service_name PID file not found"
    fi
}

# Setup Node.js version
setup_nodejs() {
    log_header "1️⃣ Setting up Node.js version"
    
    if command -v nvm > /dev/null 2>&1; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm use v22.21.1 || {
            log_info "Installing Node.js v22.21.1..."
            nvm install v22.21.1
            nvm use v22.21.1
        }
        log_success "Using Node.js $(node --version)"
    elif command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        log_success "Using system Node.js: $NODE_VERSION"
        if [[ "$NODE_VERSION" < "v20.19" ]] && [[ "$NODE_VERSION" < "v22.12" ]]; then
            log_warning "Node.js version may be too old for Angular 20"
            log_warning "Consider upgrading to v20.19+ or v22.12+"
        fi
    else
        log_error "Node.js not found! Please install Node.js v20.19+ or v22.12+"
        exit 1
    fi
}

# Start PostgreSQL
start_postgresql() {
    log_header "2️⃣ Starting PostgreSQL Database"
    
    if check_service "PostgreSQL" "docker ps | grep $POSTGRES_CONTAINER_NAME"; then
        log_success "PostgreSQL is already running"
    else
        if docker ps -a | grep $POSTGRES_CONTAINER_NAME > /dev/null; then
            log_info "Starting existing PostgreSQL container..."
            docker start $POSTGRES_CONTAINER_NAME
        else
            log_info "Creating new PostgreSQL container..."
            docker run -d --name $POSTGRES_CONTAINER_NAME \
                -e POSTGRES_DB=$POSTGRES_DB \
                -e POSTGRES_USER=$POSTGRES_USER \
                -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                -p $POSTGRES_PORT:5432 \
                postgres:$POSTGRES_VERSION
        fi
        
        wait_for_service "PostgreSQL" "docker ps | grep $POSTGRES_CONTAINER_NAME"
    fi
}

# Start .NET API
start_api() {
    log_header "3️⃣ Starting .NET API"
    
    if check_service ".NET API" "curl -s $API_HEALTH_URL -o /dev/null"; then
        log_success ".NET API is already running"
    else
        log_info "Starting .NET API in background..."
        cd "$SCRIPT_DIR/$API_PROJECT_DIR"
        
        # Set environment variables for .NET application
        export ConnectionStrings__DefaultConnection="$DB_CONNECTION_STRING"
        export ASPNETCORE_URLS="http://localhost:$API_PORT"
        
        nohup dotnet run > "$LOGS_DIR/api.log" 2>&1 &
        API_PID=$!
        echo $API_PID > "$LOGS_DIR/api.pid"
        cd "$SCRIPT_DIR"
        
        wait_for_service ".NET API" "curl -s $API_HEALTH_URL -o /dev/null"
    fi
}

# Start nginx
start_nginx() {
    log_header "4️⃣ Starting nginx Proxy"
    
    # Generate nginx config from template if available
    generate_nginx_config
    
    if check_service "nginx" "curl -s $GO_URL -o /dev/null"; then
        log_success "nginx is already running"
    else
        # Stop any existing nginx
        sudo nginx -s stop 2>/dev/null || true
        
        log_info "Starting nginx with custom configuration..."
        sudo nginx -c "$SCRIPT_DIR/$NGINX_CONFIG_FILE"
        
        wait_for_service "nginx" "ps aux | grep nginx | grep -v grep"
    fi
}

# Start Angular
start_angular() {
    log_header "5️⃣ Starting Angular Development Server"
    
    if check_service "Angular" "curl -s $ANGULAR_URL -o /dev/null"; then
        log_success "Angular is already running"
    else
        log_info "Starting Angular dev server in background..."
        cd "$SCRIPT_DIR/$ANGULAR_PROJECT_DIR"
        
        # Start Angular in background
        nohup npm start > "$LOGS_DIR/angular.log" 2>&1 &
        ANGULAR_PID=$!
        echo $ANGULAR_PID > "$LOGS_DIR/angular.pid"
        cd "$SCRIPT_DIR"
        
        wait_for_service "Angular" "curl -s $ANGULAR_URL -o /dev/null"
    fi
}

# Health check
health_check() {
    log_header "6️⃣ Final Health Check"
    
    sleep 3  # Give everything a moment to settle
    
    log_info "Testing services..."
    
    if docker ps | grep $POSTGRES_CONTAINER_NAME > /dev/null; then
        log_success "PostgreSQL: Running (Docker)"
    else
        log_error "PostgreSQL: Not running"
    fi
    
    if curl -s $API_HEALTH_URL -o /dev/null; then
        log_success ".NET API: Running on $API_URL"
    else
        log_error ".NET API: Not responding"
    fi
    
    if curl -s $ANGULAR_URL -o /dev/null; then
        log_success "Angular: Running on $ANGULAR_URL"
    else
        log_error "Angular: Not responding"
    fi
    
    if curl -s $GO_URL -o /dev/null; then
        log_success "nginx Proxy: Working at $GO_URL"
    else
        log_error "nginx Proxy: Not working"
    fi
}

# Start all services
start_all() {
    log_header "🚀 Starting GoUrls Development Environment"
    
    setup_nodejs
    start_postgresql
    start_api
    start_nginx
    start_angular
    health_check
    
    echo ""
    log_header "🎉 DEVELOPMENT ENVIRONMENT READY!"
    echo ""
    echo "📱 Access your application:"
    echo "   🔗 Main URL: $GO_URL"
    echo "   🔗 Direct Angular: $ANGULAR_URL"
    echo "   🔗 API: $API_URL"
    echo ""
    echo "📊 Service Status:"
    echo "   🐘 Database: PostgreSQL (Docker port 5431)"
    echo "   🌐 Proxy: nginx (port 80)"
    echo "   🔧 API: .NET Core (port 5165)"
    echo "   ⚡ Frontend: Angular (port 4200)"
    echo ""
    echo "📋 Useful Commands:"
    echo "   • Check status: ./dev.sh --status"
    echo "   • Stop all: ./dev.sh --stop-all"
    echo "   • Restart: ./dev.sh --restart"
    echo "   • View logs: tail -f logs/*.log"
    echo ""
    echo "Happy coding! 🚀"
}

# Stop all services
stop_all() {
    log_header "🛑 Stopping GoUrls Development Environment"
    
    log_header "1️⃣ Stopping nginx"
    sudo nginx -s stop 2>/dev/null || log_success "nginx was not running"
    
    log_header "2️⃣ Stopping Angular"
    stop_service_by_pid "Angular Dev Server" "$LOGS_DIR/angular.pid"
    pkill -f "ng serve" 2>/dev/null || true
    
    log_header "3️⃣ Stopping .NET API"
    stop_service_by_pid ".NET API" "$LOGS_DIR/api.pid"
    pkill -f "dotnet run" 2>/dev/null || true
    
    log_header "4️⃣ Stopping PostgreSQL"
    if docker ps | grep gourls-postgres > /dev/null; then
        log_info "Stopping PostgreSQL container..."
        docker stop gourls-postgres
        log_success "PostgreSQL stopped"
    else
        log_success "PostgreSQL was not running"
    fi
    
    log_header "5️⃣ Cleaning up"
    pkill -f "vite" 2>/dev/null || true
    pkill -f "webpack" 2>/dev/null || true
    
    echo ""
    log_header "✅ ALL SERVICES STOPPED!"
    echo ""
    echo "📁 Log files preserved in 'logs/' directory"
    echo "🔄 To restart everything: ./dev.sh --start-all"
}

# Restart all services
restart_all() {
    log_header "🔄 Restarting GoUrls Development Environment"
    stop_all
    echo ""
    start_all
}

# Restart specific service
restart_service() {
    local service=$1
    
    case $service in
        api)
            log_header "🔄 Restarting .NET API"
            stop_service_by_pid ".NET API" "$LOGS_DIR/api.pid"
            pkill -f "dotnet run" 2>/dev/null || true
            start_api
            log_success ".NET API restarted"
            ;;
        angular)
            log_header "🔄 Restarting Angular"
            stop_service_by_pid "Angular Dev Server" "$LOGS_DIR/angular.pid"
            pkill -f "ng serve" 2>/dev/null || true
            setup_nodejs
            start_angular
            log_success "Angular restarted"
            ;;
        nginx)
            log_header "🔄 Restarting nginx"
            sudo nginx -s stop 2>/dev/null || true
            start_nginx
            log_success "nginx restarted"
            ;;
        postgres|postgresql|db|database)
            log_header "🔄 Restarting PostgreSQL"
            if docker ps | grep gourls-postgres > /dev/null; then
                docker stop gourls-postgres
            fi
            start_postgresql
            log_success "PostgreSQL restarted"
            ;;
        *)
            log_error "Unknown service: $service"
            echo "Available services: api, angular, nginx, postgres"
            exit 1
            ;;
    esac
    
    echo ""
    echo "🔍 Service status:"
    echo "  API: $API_URL"
    echo "  Angular: $ANGULAR_URL"
    echo "  App: $GO_URL"
}

# Show status
show_status() {
    log_header "🔍 GoUrls Development Environment Status"
    
    check_service_status() {
        local name=$1
        local url=$2
        local expected_code=${3:-200}
        
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_code"; then
            log_success "$name: Running"
            return 0
        else
            log_error "$name: Not responding"
            return 1
        fi
    }
    
    echo ""
    log_info "🌐 Web Services:"
    echo "---------------"
    check_service_status "Angular Dev Server" "$ANGULAR_URL"
    check_service_status "Go Links Domain" "$GO_URL"
    check_service_status ".NET API" "$API_URL/api/urls"
    
    echo ""
    log_info "🐘 Database:"
    echo "------------"
    if docker ps | grep gourls-postgres > /dev/null; then
        log_success "PostgreSQL: Running (Docker)"
    else
        log_error "PostgreSQL: Not running"
    fi
    
    echo ""
    log_info "🔧 System Services:"
    echo "------------------"
    if ps aux | grep nginx | grep -v grep > /dev/null; then
        log_success "nginx: Running"
    else
        log_error "nginx: Not running"
    fi
    
    echo ""
    log_info "📊 Port Status:"
    echo "--------------"
    echo "Port $NGINX_PORT (nginx):"
    lsof -i :$NGINX_PORT 2>/dev/null | grep LISTEN || echo "  ❌ Nothing listening"
    
    echo "Port $ANGULAR_PORT (Angular):"
    lsof -i :$ANGULAR_PORT 2>/dev/null | grep LISTEN || echo "  ❌ Nothing listening"
    
    echo "Port $API_PORT (API):"
    lsof -i :$API_PORT 2>/dev/null | grep LISTEN || echo "  ❌ Nothing listening"
    
    echo "Port $POSTGRES_PORT (PostgreSQL):"
    lsof -i :$POSTGRES_PORT 2>/dev/null | grep LISTEN || echo "  ❌ Nothing listening"
    
    echo ""
    log_info "📁 Process IDs:"
    echo "--------------"
    if [ -f "$LOGS_DIR/angular.pid" ]; then
        echo "Angular PID: $(cat $LOGS_DIR/angular.pid)"
    else
        echo "Angular PID: Not found"
    fi
    
    if [ -f "$LOGS_DIR/api.pid" ]; then
        echo "API PID: $(cat $LOGS_DIR/api.pid)"
    else
        echo "API PID: Not found"
    fi
    
    echo ""
    log_info "📝 Recent Logs:"
    echo "--------------"
    if [ -f "$LOGS_DIR/angular.log" ]; then
        echo "Angular (last 3 lines):"
        tail -3 "$LOGS_DIR/angular.log" 2>/dev/null | sed 's/^/  /'
    else
        echo "Angular logs: Not found"
    fi
    
    if [ -f "$LOGS_DIR/api.log" ]; then
        echo "API (last 3 lines):"
        tail -3 "$LOGS_DIR/api.log" 2>/dev/null | sed 's/^/  /'
    else
        echo "API logs: Not found"
    fi
}

# Show help
show_help() {
    echo "🚀 GoUrls Development Environment Manager"
    echo "========================================"
    echo ""
    echo "Usage: ./dev.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  --start-all              🚀 Start all services"
    echo "  --stop-all               🛑 Stop all services"
    echo "  --restart                🔄 Restart all services"
    echo "  --status                 🔍 Show status of all services"
    echo "  --restart-service <svc>  🔄 Restart specific service"
    echo "  --help                   ❓ Show this help message"
    echo ""
    echo "Available services for --restart-service:"
    echo "  api, angular, nginx, postgres"
    echo ""
    echo "Examples:"
    echo "  ./dev.sh --start-all                    # Start everything"
    echo "  ./dev.sh --status                       # Check status"
    echo "  ./dev.sh --restart-service angular      # Restart just Angular"
    echo "  ./dev.sh --stop-all                     # Stop everything"
    echo ""
    echo "Access URLs after starting:"
    echo "  🔗 Main App: $GO_URL"
    echo "  🔗 Angular: $ANGULAR_URL"
    echo "  🔗 API: $API_URL"
}

# Main script logic
case "${1:-}" in
    --start-all)
        start_all
        ;;
    --stop-all)
        stop_all
        ;;
    --restart)
        restart_all
        ;;
    --status)
        show_status
        ;;
    --restart-service)
        if [ -z "${2:-}" ]; then
            log_error "Please specify a service to restart"
            echo "Available services: api, angular, nginx, postgres"
            exit 1
        fi
        restart_service "$2"
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        log_warning "No command specified. Use --help to see available commands."
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac