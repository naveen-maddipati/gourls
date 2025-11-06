#!/bin/bash

# GoUrls Docker Deployment Script
# Self-sustaining containerized deployment for GoUrls URL shortening service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment variables before setting defaults
load_env() {
    if [[ -f "$PROJECT_ROOT/environments/.env.production" ]]; then
        log_info "Loading Container Production environment variables..."
        set -a
        source "$PROJECT_ROOT/environments/.env.production"
        set +a
    elif [[ -f "$PROJECT_ROOT/environments/.env.docker" ]]; then
        log_info "Loading Docker environment variables..."
        set -a
        source "$PROJECT_ROOT/environments/.env.docker"
        set +a
    else
        log_warning "No production environment file found (environments/.env.production or environments/.env.docker)"
        log_info "Using default container configuration..."
    fi
}

# Load environment first (will be called again later but needed for PROJECT_NAME)
if [[ -f "$PROJECT_ROOT/environments/.env.production" ]]; then
    set -a
    source "$PROJECT_ROOT/environments/.env.production"
    set +a
fi

# Use environment variables with fallback defaults
PROJECT_NAME="${PROJECT_NAME:-gourls}"
GO_DOMAIN="${GO_DOMAIN:-go}"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_header() {
    echo -e "\n${PURPLE}$1${NC}"
    echo "$(printf '=%.0s' {1..50})"
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

show_help() {
    cat << EOF
🐳 GoUrls Docker Deployment Script

USAGE:
    ./deploy-gourls.sh [COMMAND] [OPTIONS]

COMMANDS:
    --build         Build all Docker images
    --start         Start all services
    --stop          Stop all services  
    --restart       Restart all services
    --status        Show status of all services
    --logs          Show logs for all services
    --logs <service> Show logs for specific service
    --clean         Remove all containers and images
    --reset         Clean and rebuild everything
    --shell <service> Open shell in running container
    --backup        Backup database
    --restore <file> Restore database from backup
    --update        Pull latest images and restart
    --setup-hosts   Setup hosts file for production domain
    --remove-hosts  Remove hosts file entry for production domain
    --check-hosts   Check if hosts file is configured
    --help          Show this help message

EXAMPLES:
    ./deploy-gourls.sh --start          # Start the application
    ./deploy-gourls.sh --logs api       # View API logs
    ./deploy-gourls.sh --shell postgres # Connect to database
    ./deploy-gourls.sh --setup-hosts    # Configure hosts file
    ./deploy-gourls.sh --backup         # Backup database
    ./deploy-gourls.sh --clean          # Clean everything

SERVICES:
    postgres      PostgreSQL database
    api           .NET Core API backend  
    frontend      Angular frontend
    nginx         Reverse proxy

ACCESS:
    Main App:     http://localhost (or http://$GO_DOMAIN if hosts configured)
    API Direct:   http://localhost:${API_PORT:-5000}
    Frontend:     http://localhost:${FRONTEND_PORT:-8080}
    Database:     localhost:5432

EOF
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    log_success "All dependencies are installed"
}

# Hosts file management functions
check_hosts_entry() {
    local domain=${1:-$GO_DOMAIN}
    if grep -q "127.0.0.1[[:space:]]*$domain" /etc/hosts 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

add_hosts_entry() {
    local domain=${1:-$GO_DOMAIN}
    
    if check_hosts_entry "$domain"; then
        log_info "Hosts entry for '$domain' already exists"
        return 0
    fi
    
    log_info "Adding '$domain' to /etc/hosts (requires sudo)..."
    
    # Check if user has sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warning "This operation requires administrator privileges."
        echo "Please enter your password to add '$domain' to /etc/hosts:"
    fi
    
    # Create backup
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Add entry
    if echo "127.0.0.1   $domain" | sudo tee -a /etc/hosts > /dev/null; then
        log_success "Added '$domain' to /etc/hosts"
        return 0
    else
        log_error "Failed to add '$domain' to /etc/hosts"
        return 1
    fi
}

remove_hosts_entry() {
    local domain=${1:-$GO_DOMAIN}
    
    if ! check_hosts_entry "$domain"; then
        log_info "No hosts entry found for '$domain'"
        return 0
    fi
    
    log_info "Removing '$domain' from /etc/hosts (requires sudo)..."
    
    # Check if user has sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warning "This operation requires administrator privileges."
        echo "Please enter your password to remove '$domain' from /etc/hosts:"
    fi
    
    # Create backup
    sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    # Remove entry
    if sudo sed -i.bak "/127\.0\.0\.1[[:space:]]*$domain/d" /etc/hosts; then
        log_success "Removed '$domain' from /etc/hosts"
        return 0
    else
        log_error "Failed to remove '$domain' from /etc/hosts"
        return 1
    fi
}

setup_hosts() {
    local domain=${1:-$GO_DOMAIN}
    log_header "Setting up hosts file for '$domain' domain"
    
    if check_hosts_entry "$domain"; then
        log_success "Hosts entry for '$domain' is already configured"
    else
        log_info "Setting up hosts entry for '$domain' domain..."
        if add_hosts_entry "$domain"; then
            log_success "Hosts configuration complete - you can now access via http://$domain/"
        else
            log_error "Failed to configure hosts file"
            log_warning "You can manually add this line to /etc/hosts:"
            echo "    127.0.0.1   $domain"
            return 1
        fi
    fi
}

build_images() {
    log_header "🔨 Building Docker Images"
    load_env
    
    log_info "Building all images..."
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    log_success "All images built successfully!"
}

start_services() {
    log_header "🚀 Starting GoUrls Services"
    load_env
    
    # Set up user management defaults for production
    export CURRENT_USER="${CURRENT_USER:-system}"
    export AUTHENTICATION_DEFAULT_USER="${AUTHENTICATION_DEFAULT_USER:-system}"
    export AUTHENTICATION_MODE="${AUTHENTICATION_MODE:-Environment}"
    
    log_info "User management configuration:"
    echo "   Current user: ${CURRENT_USER}"
    echo "   Default user: ${AUTHENTICATION_DEFAULT_USER}" 
    echo "   Auth mode: ${AUTHENTICATION_MODE}"
    
    # Setup hosts file for production domain
    setup_hosts $GO_DOMAIN
    
    log_info "Starting all services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    check_service_health
    
    show_access_info
}

stop_services() {
    log_header "🛑 Stopping GoUrls Services"
    
    log_info "Stopping all services..."
    docker-compose -f "$COMPOSE_FILE" down
    
    log_success "All services stopped!"
}

restart_services() {
    log_header "🔄 Restarting GoUrls Services"
    stop_services
    sleep 2
    start_services
}

show_status() {
    log_header "📊 GoUrls Services Status"
    
    echo -e "${CYAN}Container Status:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps
    
    echo -e "\n${CYAN}Service Health:${NC}"
    check_service_health
    
    echo -e "\n${CYAN}Resource Usage:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker-compose -f "$COMPOSE_FILE" ps -q) 2>/dev/null || echo "No containers running"
}

check_service_health() {
    local services=("postgres:5432" "api:${API_PORT}" "frontend:80" "nginx:80")
    
    for service in "${services[@]}"; do
        local name="${service%%:*}"
        local port="${service##*:}"
        local container="${PROJECT_NAME}-${name}"
        
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            if [[ "$name" == "postgres" ]]; then
                if docker exec "$container" pg_isready -U postgres > /dev/null 2>&1; then
                    echo -e "  ${GREEN}✅ $name${NC} - Running and healthy"
                else
                    echo -e "  ${YELLOW}⚠️  $name${NC} - Running but not ready"
                fi
            else
                if curl -f -s "http://localhost:$port/health" > /dev/null 2>&1 || curl -f -s "http://localhost:$port" > /dev/null 2>&1; then
                    echo -e "  ${GREEN}✅ $name${NC} - Running and healthy"
                else
                    echo -e "  ${YELLOW}⚠️  $name${NC} - Running but not responding"
                fi
            fi
        else
            echo -e "  ${RED}❌ $name${NC} - Not running"
        fi
    done
}

show_logs() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        log_header "📋 All Service Logs"
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=50
    else
        log_header "📋 $service Service Logs"
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=50 "$service"
    fi
}

clean_everything() {
    log_header "🧹 Cleaning Up Everything"
    
    log_warning "This will remove all containers, images, and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Stopping and removing containers..."
        docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
        
        log_info "Removing images..."
        docker images | grep "$PROJECT_NAME" | awk '{print $3}' | xargs -r docker rmi -f
        
        log_info "Cleaning up unused resources..."
        docker system prune -f
        
        log_success "Everything cleaned up!"
    else
        log_info "Cleanup cancelled."
    fi
}

reset_everything() {
    log_header "🔄 Resetting Everything"
    clean_everything
    build_images
    start_services
}

open_shell() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        log_error "Please specify a service: postgres, api, frontend, nginx"
        log_info "Usage: ./deploy-docker.sh --shell <service>"
        exit 1
    fi
    
    local container="${PROJECT_NAME}-${service}"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_error "Container $container is not running"
        exit 1
    fi
    
    log_info "Opening shell in $service container..."
    
    case "$service" in
        postgres)
            docker exec -it "$container" psql -U postgres -d gourls
            ;;
        api)
            docker exec -it "$container" /bin/bash
            ;;
        frontend|nginx)
            docker exec -it "$container" /bin/sh
            ;;
        *)
            docker exec -it "$container" /bin/bash 2>/dev/null || docker exec -it "$container" /bin/sh
            ;;
    esac
}

backup_database() {
    log_header "💾 Creating Database Backup"
    
    local backup_file="gourls_backup_$(date +%Y%m%d_%H%M%S).sql"
    local container="${PROJECT_NAME}-postgres"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_error "PostgreSQL container is not running"
        exit 1
    fi
    
    log_info "Creating backup: $backup_file"
    docker exec "$container" pg_dump -U postgres -d gourls > "$backup_file"
    
    log_success "Database backup created: $backup_file"
}

restore_database() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        log_error "Please specify a backup file"
        log_info "Usage: ./deploy-docker.sh --restore <backup_file>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    log_header "📥 Restoring Database"
    
    local container="${PROJECT_NAME}-postgres"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_error "PostgreSQL container is not running"
        exit 1
    fi
    
    log_warning "This will overwrite the current database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restoring from: $backup_file"
        cat "$backup_file" | docker exec -i "$container" psql -U postgres -d gourls
        log_success "Database restored successfully!"
    else
        log_info "Restore cancelled."
    fi
}

update_services() {
    log_header "🔄 Updating Services"
    
    log_info "Pulling latest images..."
    docker-compose -f "$COMPOSE_FILE" pull
    
    log_info "Rebuilding custom images..."
    docker-compose -f "$COMPOSE_FILE" build --no-cache
    
    log_info "Restarting services..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    log_success "Services updated and restarted!"
}

show_access_info() {
    log_success "GoUrls is now running!"
    
    # Check if hosts is configured
    local hosts_status=""
    if check_hosts_entry $GO_DOMAIN; then
        hosts_status="✅ http://$GO_DOMAIN/ (hosts configured)"
    else
        hosts_status="⚠️  http://$GO_DOMAIN/ (run --setup-hosts first)"
    fi
    
    cat << EOF

${CYAN}🌐 Access URLs:${NC}
  Main App:     http://localhost 
  Go Domain:    $hosts_status
  API Direct:   http://localhost:${API_PORT:-5000}  
  Frontend:     http://localhost:${FRONTEND_PORT:-8080}
  Health Check: http://localhost/health

${CYAN}📊 Management Commands:${NC}
  Status:       ./deploy-gourls.sh --status
  Logs:         ./deploy-gourls.sh --logs
  Stop:         ./deploy-gourls.sh --stop
  Database:     ./deploy-gourls.sh --shell postgres

${CYAN}🌐 Hosts Configuration:${NC}
  Setup:        ./deploy-gourls.sh --setup-hosts
  Check:        ./deploy-gourls.sh --check-hosts
  Remove:       ./deploy-gourls.sh --remove-hosts

${CYAN}💾 Database:${NC}
  Backup:       ./deploy-gourls.sh --backup
  Connect:      ./deploy-gourls.sh --shell postgres

Happy URL shortening! 🚀

EOF
}

# Main command processing
case "${1:-help}" in
    --build)
        check_dependencies
        build_images
        ;;
    --start)
        check_dependencies
        start_services
        ;;
    --stop)
        stop_services
        ;;
    --restart)
        restart_services
        ;;
    --status)
        show_status
        ;;
    --logs)
        show_logs "$2"
        ;;
    --clean)
        clean_everything
        ;;
    --reset)
        reset_everything
        ;;
    --shell)
        open_shell "$2"
        ;;
    --backup)
        backup_database
        ;;
    --restore)
        restore_database "$2"
        ;;
    --update)
        update_services
        ;;
    --setup-hosts)
        setup_hosts $GO_DOMAIN
        ;;
    --remove-hosts)
        remove_hosts_entry $GO_DOMAIN
        ;;
    --check-hosts)
        if check_hosts_entry $GO_DOMAIN; then
            log_success "Hosts entry for '$GO_DOMAIN' is configured"
            echo "  ✅ 127.0.0.1   $GO_DOMAIN"
            echo "  🔗 Access via: http://$GO_DOMAIN/"
        else
            log_warning "Hosts entry for '$GO_DOMAIN' is not configured"
            echo "  ❌ Missing: 127.0.0.1   $GO_DOMAIN"
            echo ""
            echo "Run: ./deploy-gourls.sh --setup-hosts"
        fi
        ;;
    --help|help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use './deploy-gourls.sh --help' to see available commands."
        exit 1
        ;;
esac