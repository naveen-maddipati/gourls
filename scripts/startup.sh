#!/bin/bash

# ${PROJECT_NAME} Development Environment Manager
# Usage: ./startup.sh [--start-all|--stop-all|--restart|--status|--restart-service <service>|--help]

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment configuration
load_env_config() {
    local defaults_file="$SCRIPT_DIR/../environments/.env.defaults"
    local development_file="$SCRIPT_DIR/../environments/.env.development"
    local local_file="$SCRIPT_DIR/../environments/.env.local"
    local legacy_env_file="$SCRIPT_DIR/../environments/.env"
    
    # Load defaults first (non-sensitive, committed to git)
    if [[ -f "$defaults_file" ]]; then
        echo "🔧 Loading default configuration from .env.defaults..."
        set -a  # Automatically export all variables
        source "$defaults_file"
        set +a  # Stop auto-exporting
    fi
    
    # Load development configuration (local development settings)
    if [[ -f "$development_file" ]]; then
        echo "🔧 Loading development configuration from .env.development..."
        set -a  # Automatically export all variables
        source "$development_file"
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
        echo "   💡 Consider migrating to .env.defaults + .env.development + .env.local structure"
        set -a  # Automatically export all variables
        source "$legacy_env_file"
        set +a  # Stop auto-exporting
    else
        echo "⚠️  No local configuration files found."
        echo "   Create .env.local from .env.local.example for local settings"
    fi
    
    # Validate required environment variables are loaded from files
    # No fallback values - force proper environment configuration
    if [[ -z "$PROJECT_NAME" ]]; then echo "❌ PROJECT_NAME not set in environment files"; exit 1; fi
    if [[ -z "$GO_DOMAIN" ]]; then echo "❌ GO_DOMAIN not set in environment files"; exit 1; fi
    if [[ -z "$NGINX_PORT" ]]; then echo "❌ NGINX_PORT not set in environment files"; exit 1; fi
    if [[ -z "$FRONTEND_PORT" ]]; then echo "❌ FRONTEND_PORT not set in environment files"; exit 1; fi
    if [[ -z "$API_PORT" ]]; then echo "❌ API_PORT not set in environment files"; exit 1; fi
    if [[ -z "$POSTGRES_PORT" ]]; then echo "❌ POSTGRES_PORT not set in environment files"; exit 1; fi
    if [[ -z "$POSTGRES_HOST" ]]; then echo "❌ POSTGRES_HOST not set in environment files"; exit 1; fi
    if [[ -z "$POSTGRES_DB" ]]; then echo "❌ POSTGRES_DB not set in environment files"; exit 1; fi
    if [[ -z "$POSTGRES_USER" ]]; then echo "❌ POSTGRES_USER not set in environment files"; exit 1; fi
    if [[ -z "$POSTGRES_PASSWORD" ]]; then echo "❌ POSTGRES_PASSWORD not set in environment files"; exit 1; fi
    
    # Only set minimal defaults for non-critical values
    POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME:-gourls-postgres-dev}
    POSTGRES_VERSION=${POSTGRES_VERSION:-15}
    API_PROJECT_DIR=${API_PROJECT_DIR:-GoUrlsApi}
    ANGULAR_PROJECT_DIR=${ANGULAR_PROJECT_DIR:-go-urls-app}
    NODE_VERSION_REQUIRED=${NODE_VERSION_REQUIRED:-22.21.1}
    NGINX_CONFIG_FILE=${NGINX_CONFIG_FILE:-nginx-go-proxy.conf}
    
    # User management defaults
    AUTHENTICATION_MODE=${AUTHENTICATION_MODE:-Environment}
    CURRENT_USER=${CURRENT_USER:-$(whoami)}
    
    # Set computed values
    LOGS_DIR="${LOGS_DIR:-logs}"
    # Ensure LOGS_DIR is absolute
    if [[ ! "$LOGS_DIR" = /* ]]; then
        LOGS_DIR="$SCRIPT_DIR/$LOGS_DIR"
    fi
    ANGULAR_URL="http://localhost:${FRONTEND_PORT}"
    API_URL="http://localhost:${API_PORT}"
    API_HEALTH_URL="http://localhost:${API_PORT}/api/urls"
    GO_URL="http://${GO_DOMAIN}"
    DB_CONNECTION_STRING="Host=${POSTGRES_HOST};Port=${POSTGRES_PORT};Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD}"
}

# Load configuration first
load_env_config

# Validate environment separation
validate_environment() {
    log_info "🔍 Development Environment Validation:"
    echo "   Mode: Development"
    echo "   Database: $POSTGRES_DB (port $POSTGRES_PORT)"
    echo "   Container: $POSTGRES_CONTAINER_NAME"
    
    # Warn if any production containers are detected
    if docker ps | grep "gourls-postgres" | grep -v "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_warning "Production-like containers detected running separately"
        log_info "Development environment will use isolated database"
    fi
    
    # Ensure development-specific settings
    if [[ "$POSTGRES_DB" == "gourls" ]] && [[ "$POSTGRES_CONTAINER_NAME" == "gourls-postgres" ]]; then
        log_error "Configuration appears to be using production-like settings!"
        log_error "Please ensure .env.development is properly configured"
        return 1
    fi
    
    log_success "Development environment validation passed"
}

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
    log_header "Setting up hosts file"
    
    if check_hosts_entry "$GO_DOMAIN"; then
        log_success "Hosts entry for '$GO_DOMAIN' is already configured"
    else
        log_info "Setting up hosts entry for '$GO_DOMAIN' domain..."
        if add_hosts_entry "$GO_DOMAIN"; then
            log_success "Hosts configuration complete"
        else
            log_error "Failed to configure hosts file"
            log_warning "You can manually add this line to /etc/hosts:"
            echo "    127.0.0.1   $GO_DOMAIN"
            return 1
        fi
    fi
    
    # Show access information
    log_info "Access configuration:"
    if [[ "$GO_DOMAIN" == "go.local" ]]; then
        echo "   � Environment: Development"
        echo "   🔗 URL: http://$GO_DOMAIN:$NGINX_PORT"
        echo "   🔌 Port: $NGINX_PORT (dev range: 2001-2999)"
    else
        echo "   🏭 Environment: Production"  
        echo "   🔗 URL: http://$GO_DOMAIN:$NGINX_PORT"
        echo "   🔌 Port: $NGINX_PORT (prod range: 3001-3999)"
    fi
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
    local template_file="$SCRIPT_DIR/../nginx-go-proxy.conf.template"
    local output_file="$SCRIPT_DIR/../$NGINX_CONFIG_FILE"
    
    if [[ -f "$template_file" ]]; then
        log_info "Generating nginx config from template..."
        
        # Convert RESERVED_WORDS comma-separated list to nginx regex pattern
        local reserved_pattern=""
        if [[ -n "$RESERVED_WORDS" ]]; then
            # Convert "word1,word2,word3" to "(word1|word2|word3)"
            reserved_pattern=$(echo "$RESERVED_WORDS" | sed 's/,/|/g')
            reserved_pattern="($reserved_pattern)"
        fi
        
        # Use sed to replace template variables with actual values
        sed -e "s|{{NGINX_PORT}}|$NGINX_PORT|g" \
            -e "s|{{GO_DOMAIN}}|$GO_DOMAIN|g" \
            -e "s|{{ANGULAR_URL}}|$ANGULAR_URL|g" \
            -e "s|{{FRONTEND_PORT}}|$FRONTEND_PORT|g" \
            -e "s|{{API_URL}}|$API_URL|g" \
            -e "s#{{RESERVED_PATTERN}}#$reserved_pattern#g" \
            "$template_file" > "$output_file"
        
        log_success "nginx config generated: $output_file"
    else
        log_info "No nginx template found, using existing config file"
    fi
}

# Function to generate launchSettings.json from template
generate_launch_settings() {
    local template_file="$SCRIPT_DIR/../GoUrlsApi/Properties/launchSettings.json.template"
    local output_file="$SCRIPT_DIR/../GoUrlsApi/Properties/launchSettings.json"
    
    if [[ -f "$template_file" ]]; then
        log_info "Generating launchSettings.json from template..."
        
        # Use sed to replace template variables with actual values
        sed -e "s|{{API_PORT}}|$API_PORT|g" \
            "$template_file" > "$output_file"
        
        log_success "launchSettings.json generated: $output_file"
    else
        log_info "No launchSettings template found, using existing config file"
    fi
}

# Function to generate Angular constants from environment
generate_angular_constants() {
    local constants_file="$SCRIPT_DIR/../$ANGULAR_PROJECT_DIR/src/app/core/constants.ts"
    
    log_info "Generating Angular constants from environment..."
    
    cat > "$constants_file" << EOF
// 🚀 Application Constants
// This file is auto-generated from environment variables by startup.sh
// DO NOT EDIT MANUALLY - Changes will be overwritten

export const Base_Url = '$API_URL/';
export const Go_Domain = '$GO_URL';

// Environment information
export const Environment = {
  apiUrl: '$API_URL',
  goDomain: '$GO_URL',
  domain: '$GO_DOMAIN',
  isProduction: false,
  generatedAt: '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
};
EOF
    
    log_success "Angular constants generated: $constants_file"
}

# Function to generate Angular configuration files from templates
generate_angular_configs() {
    local angular_dir="$SCRIPT_DIR/../$ANGULAR_PROJECT_DIR"
    
    # Generate angular.json from template
    local angular_template="$angular_dir/angular.json.template"
    local angular_config="$angular_dir/angular.json"
    
    if [[ -f "$angular_template" ]]; then
        log_info "Generating angular.json from template..."
        
        sed -e "s/{{GO_DOMAIN}}/$GO_DOMAIN/g" \
            -e "s/{{FRONTEND_PORT}}/$FRONTEND_PORT/g" \
            "$angular_template" > "$angular_config"
        
        log_success "Angular config generated: $angular_config"
    else
        log_warning "Angular template not found: $angular_template"
    fi
    
    # Generate proxy.conf.json from template
    local proxy_template="$angular_dir/proxy.conf.json.template"
    local proxy_config="$angular_dir/proxy.conf.json"
    
    if [[ -f "$proxy_template" ]]; then
        log_info "Generating proxy.conf.json from template..."
        
        sed -e "s/{{API_PORT}}/$API_PORT/g" \
            "$proxy_template" > "$proxy_config"
        
        log_success "Angular proxy config generated: $proxy_config"
    else
        log_warning "Proxy template not found: $proxy_template"
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
    
    # Try to source nvm more reliably
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        export NVM_DIR="$HOME/.nvm"
        source "$NVM_DIR/nvm.sh"
        source "$NVM_DIR/bash_completion" 2>/dev/null || true
        
        log_info "Switching to Node.js v$NODE_VERSION_REQUIRED..."
        if nvm use "v$NODE_VERSION_REQUIRED" 2>/dev/null; then
            log_success "Using Node.js $(node --version)"
        else
            log_info "Installing Node.js v$NODE_VERSION_REQUIRED..."
            nvm install "v$NODE_VERSION_REQUIRED"
            nvm use "v$NODE_VERSION_REQUIRED"
            log_success "Installed and using Node.js $(node --version)"
        fi
    elif command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        log_success "Using system Node.js: $NODE_VERSION"
        if [[ "$NODE_VERSION" < "v20.19" ]] && [[ "$NODE_VERSION" < "v22.12" ]]; then
            log_warning "Node.js version may be too old for Angular 20"
            log_warning "Consider upgrading to v20.19+ or v22.12+"
            log_warning "Or install nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash"
        fi
    else
        log_error "Node.js not found! Please install Node.js v20.19+ or v22.12+"
        log_info "Install nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash"
        exit 1
    fi
}

# Start PostgreSQL
start_postgresql() {
    log_header "2️⃣ Starting PostgreSQL Database (Development)"
    
    # Ensure we're using development-specific configuration
    log_info "Development Database Configuration:"
    echo "   📦 Container: $POSTGRES_CONTAINER_NAME"
    echo "   🔌 Port: $POSTGRES_PORT"
    echo "   🗄️ Database: $POSTGRES_DB"
    echo "   👤 User: $POSTGRES_USER"
    
    if check_service "PostgreSQL" "docker ps | grep $POSTGRES_CONTAINER_NAME"; then
        log_success "Development PostgreSQL is already running"
    else
        # Inform about other containers (but don't interfere)
        if docker ps | grep "postgres" | grep -v "$POSTGRES_CONTAINER_NAME" > /dev/null; then
            log_info "Other PostgreSQL containers detected - development will use separate container"
        fi
        
        if docker ps -a | grep $POSTGRES_CONTAINER_NAME > /dev/null; then
            log_info "Starting existing development PostgreSQL container..."
            docker start $POSTGRES_CONTAINER_NAME
        else
            log_info "Creating new development PostgreSQL container..."
            log_info "This will be isolated from any other database containers"
            
            # Remove any existing container with the same name
            docker rm -f $POSTGRES_CONTAINER_NAME 2>/dev/null || true
            
            # Create development-specific PostgreSQL container
            docker run -d --name $POSTGRES_CONTAINER_NAME \
                -e POSTGRES_DB=$POSTGRES_DB \
                -e POSTGRES_USER=$POSTGRES_USER \
                -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
                -p $POSTGRES_PORT:5432 \
                --restart unless-stopped \
                -v ${POSTGRES_CONTAINER_NAME}_data:/var/lib/postgresql/data \
                postgres:$POSTGRES_VERSION
                
            log_success "Development PostgreSQL container created with dedicated volume"
        fi
        
        wait_for_service "PostgreSQL" "docker ps | grep $POSTGRES_CONTAINER_NAME"
        
        # Verify database connection
        log_info "Verifying database connection..."
        sleep 2
        if docker exec $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT version();" > /dev/null 2>&1; then
            log_success "Development database is ready and accessible"
            
            # Run database migrations for new development database
            log_info "Checking if database schema exists..."
            if ! docker exec $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -c "\dt" 2>/dev/null | grep -q "Urls"; then
                log_info "Development database is new, running migrations..."
                cd "$SCRIPT_DIR/../$API_PROJECT_DIR"
                
                # Set the connection string for migrations
                export ConnectionStrings__DefaultConnection="$DB_CONNECTION_STRING"
                
                # Run migrations
                if dotnet ef database update --no-build 2>/dev/null; then
                    log_success "Database migrations completed successfully"
                    log_info "Note: Seed data will be automatically restored when API starts"
                else
                    log_warning "Migration failed, will retry after API starts"
                fi
                cd "$SCRIPT_DIR"
            else
                log_success "Database schema already exists"
                log_info "Note: Missing seed data will be automatically restored when API starts"
            fi
        else
            log_warning "Database may still be initializing, this is normal for new containers"
        fi
    fi
}

# Start .NET API
start_api() {
    log_header "3️⃣ Starting .NET API"
    
    # Generate launchSettings.json from template if available
    generate_launch_settings
    
    if check_service ".NET API" "curl -s $API_HEALTH_URL -o /dev/null"; then
        log_success ".NET API is already running"
    else
        log_info "Starting .NET API in background..."
        cd "$SCRIPT_DIR/../$API_PROJECT_DIR"
        
        # Set environment variables for .NET application
        export ConnectionStrings__DefaultConnection="$DB_CONNECTION_STRING"
        export ASPNETCORE_URLS="http://localhost:$API_PORT"
        export ASPNETCORE_ENVIRONMENT="Development"
        export RESERVED_WORDS="$RESERVED_WORDS"
        
        # User management environment variables
        export CURRENT_USER="${USER:-$(whoami)}"
        export Authentication__DefaultUser="${CURRENT_USER}"
        export Authentication__Mode="${AUTHENTICATION_MODE:-Environment}"
        
        log_info "Using development database: $POSTGRES_DB on port $POSTGRES_PORT"
        
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
        sudo nginx -c "$SCRIPT_DIR/../$NGINX_CONFIG_FILE"
        
        wait_for_service "nginx" "ps aux | grep nginx | grep -v grep"
    fi
}

# Start Angular
start_angular() {
    log_header "5️⃣ Starting Angular Development Server"
    
    # Generate Angular constants from environment
    generate_angular_constants
    generate_angular_configs
    
    if check_service "Angular" "curl -s $ANGULAR_URL -o /dev/null"; then
        log_success "Angular is already running"
    else
        log_info "Starting Angular dev server in background..."
        cd "$SCRIPT_DIR/../$ANGULAR_PROJECT_DIR"
        
        # Ensure nvm environment is available for Angular process
        if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            export NVM_DIR="$HOME/.nvm"
            source "$NVM_DIR/nvm.sh"
            nvm use "v$NODE_VERSION_REQUIRED" 2>/dev/null || true
        fi
        
        # Ensure we use the correct Node.js version
        if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
            export NVM_DIR="$HOME/.nvm"
            source "$NVM_DIR/nvm.sh"
            nvm use "v$NODE_VERSION_REQUIRED" 2>/dev/null || true
        fi
        
        # Start Angular in background with proper environment
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
    log_header "🚀 Starting ${PROJECT_NAME} Development Environment"
    
    # Validate environment configuration
    validate_environment
    
    setup_hosts
    setup_nodejs
    generate_nginx_config
    generate_angular_constants
    generate_angular_configs
    start_postgresql
    start_api
    start_nginx
    start_angular
    health_check
    
    echo ""
    log_header "🎉 DEVELOPMENT ENVIRONMENT READY!"
    echo ""
    echo "📱 Access your application:"
    echo "   🔗 Main URL: http://$GO_DOMAIN:$FRONTEND_PORT (Development - Direct Angular)"
    echo "   🔗 Alternative: http://localhost:$FRONTEND_PORT (localhost access)"
    echo "   🔗 API: http://localhost:$API_PORT"
    echo ""
    echo "📊 Service Status:"
    echo "   🐘 Database: PostgreSQL (Development - port $POSTGRES_PORT)"
    echo "   🗄️ Database Name: $POSTGRES_DB"
    echo "   📦 Container: $POSTGRES_CONTAINER_NAME"
    echo "   🌐 Proxy: nginx (port $NGINX_PORT)"
    echo "   🔧 API: .NET Core (port $API_PORT)"
    echo "   ⚡ Frontend: Angular (port $FRONTEND_PORT)"
    echo ""
    echo "🔒 Environment Isolation:"
    echo "   ✅ Development database is isolated from production"
    echo "   ✅ Uses dedicated container and data volume"
    echo "   ✅ Different port ($POSTGRES_PORT) from production (5432)"
    echo ""
    echo "📋 Useful Commands:"
    echo "   • Check status: ./startup.sh --status"
    echo "   • Stop all: ./startup.sh --stop-all"
    echo "   • Restart: ./startup.sh --restart"
    echo "   • View logs: tail -f logs/*.log"
    echo ""
    echo "Happy coding! 🚀"
}

# Stop all services
stop_all() {
    log_header "🛑 Stopping ${PROJECT_NAME} Development Environment"
    
    log_header "1️⃣ Stopping nginx"
    sudo nginx -s stop 2>/dev/null || log_success "nginx was not running"
    
    log_header "2️⃣ Stopping Angular"
    stop_service_by_pid "Angular Dev Server" "$LOGS_DIR/angular.pid"
    pkill -f "ng serve" 2>/dev/null || true
    
    log_header "3️⃣ Stopping .NET API"
    stop_service_by_pid ".NET API" "$LOGS_DIR/api.pid"
    pkill -f "dotnet run" 2>/dev/null || true
    
    log_header "4️⃣ Stopping PostgreSQL"
    if docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_info "Stopping existing PostgreSQL container..."
        docker stop "$POSTGRES_CONTAINER_NAME"
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
    log_header "🔄 Restarting ${PROJECT_NAME} Development Environment"
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
            generate_angular_constants
            generate_angular_configs
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
            if docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
                docker stop "$POSTGRES_CONTAINER_NAME"
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
    log_header "🔍 ${PROJECT_NAME} Development Environment Status"
    
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
    if docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_success "Development PostgreSQL: Running (Docker)"
        echo "   📦 Container: $POSTGRES_CONTAINER_NAME"
        echo "   🔌 Port: $POSTGRES_PORT"
        echo "   🗄️ Database: $POSTGRES_DB"
        
        # Note about other containers (but don't interfere)
        if docker ps | grep "postgres" | grep -v "$POSTGRES_CONTAINER_NAME" > /dev/null; then
            log_info "Other PostgreSQL containers also detected"
            echo "   ℹ️  Development database is isolated"
        else
            log_success "Development database running independently"
        fi
    else
        log_error "Development PostgreSQL: Not running"
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
    
    echo "Port $FRONTEND_PORT (Angular):"
    lsof -i :$FRONTEND_PORT 2>/dev/null | grep LISTEN || echo "  ❌ Nothing listening"
    
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
    echo "Recent Logs:"
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
    
    echo ""
    log_info "💡 Additional Commands:"
    echo "----------------------"
    echo "For detailed database status and isolation info: ./startup.sh --db-status"
}

# Show database status
show_database_status() {
    log_header "🔍 Development Database Status"
    
    echo ""
    log_info "📊 Development PostgreSQL Container:"
    echo "-----------------------------------"
    
    # Show development database container
    if docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" | head -1
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}" | grep "$POSTGRES_CONTAINER_NAME"
    else
        echo "   ❌ Development PostgreSQL container not running"
    fi
    
    echo ""
    log_info "🗄️ Development Database Contents:"
    echo "--------------------------------"
    
    # Check development database
    echo -e "${GREEN}Development Database ($POSTGRES_DB):${NC}"
    if docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        local dev_count=$(docker exec $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT COUNT(*) FROM \"Urls\";" 2>/dev/null | tr -d ' ')
        if [[ "$dev_count" =~ ^[0-9]+$ ]]; then
            echo "   📊 Total URLs: $dev_count"
            if [ "$dev_count" -gt 0 ]; then
                echo "   📋 Sample URLs:"
                docker exec $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT \"ShortName\", \"LongUrl\" FROM \"Urls\" LIMIT 3;" 2>/dev/null | grep -E "^\s" | sed 's/^/      /' || echo "      No URLs found"
            else
                echo "   📋 No URLs in development database"
            fi
        else
            echo "   ❌ Cannot access development database"
        fi
    else
        echo "   ❌ Development container not running"
    fi
    
    echo ""
    log_info "� Development Connection Details:"
    echo "---------------------------------"
    echo "   Database URL: localhost:$POSTGRES_PORT/$POSTGRES_DB"
    echo "   Container: $POSTGRES_CONTAINER_NAME"
    echo "   Manual connection: docker exec -it $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB"
    
    echo ""
    if docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_success "✅ Development database is running and isolated"
        echo ""
        log_info "💡 Note: This script manages development environment only"
        echo "   For production database management, use deploy-gourls.sh"
    else
        log_warning "⚠️  Development database is not running"
        echo "   Use: ./startup.sh --start-all"
    fi
}

# Database migration management
run_migrations() {
    log_header "🗄️ Running Database Migrations"
    
    if ! docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_error "Development database is not running"
        log_info "Start the database first: ./startup.sh --start-all"
        return 1
    fi
    
    log_info "Running EF Core migrations on development database..."
    cd "$SCRIPT_DIR/../$API_PROJECT_DIR"
    
    # Set the connection string for migrations
    export ConnectionStrings__DefaultConnection="$DB_CONNECTION_STRING"
    
    # Run migrations
    if dotnet ef database update; then
        log_success "Database migrations completed successfully"
        log_info "This includes any seed data from EF Core seeding"
    else
        log_error "Migration failed"
        return 1
    fi
    cd "$SCRIPT_DIR"
}

# Reset development database
reset_database() {
    log_header "🔄 Resetting Development Database"
    
    log_warning "This will completely reset the development database!"
    log_warning "All data will be lost, including manually created URLs."
    echo ""
    echo -n "Are you sure you want to continue? (type 'yes' to confirm): "
    read confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log_info "Database reset cancelled"
        return 0
    fi
    
    log_info "Stopping and removing development database container..."
    docker stop "$POSTGRES_CONTAINER_NAME" 2>/dev/null || true
    docker rm "$POSTGRES_CONTAINER_NAME" 2>/dev/null || true
    
    log_info "Removing database volume..."
    docker volume rm "${POSTGRES_CONTAINER_NAME}_data" 2>/dev/null || true
    
    log_info "Recreating fresh database..."
    start_postgresql
    
    log_info "Running all migrations including seed data..."
    run_migrations
    
    log_success "Development database has been reset with fresh seed data!"
}

# Check seed data
check_seed_data() {
    log_header "📊 Checking Seed Data"
    
    if ! docker ps | grep "$POSTGRES_CONTAINER_NAME" > /dev/null; then
        log_error "Development database is not running"
        log_info "Start the database first: ./startup.sh --start-all"
        return 1
    fi
    
    log_info "Checking for seed data in development database..."
    
    # Check if API is running
    if ! curl -s http://localhost:$API_PORT/api/urls -o /dev/null; then
        log_warning "API is not running, checking database directly..."
        
        local count=$(docker exec $POSTGRES_CONTAINER_NAME psql -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT COUNT(*) FROM \"Urls\" WHERE \"Id\" LIKE '550e8400-e29b-41d4-a716-44665544000%';" 2>/dev/null | tr -d ' ')
        
        if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" -gt 0 ]; then
            log_success "Found $count seeded URL entries in database"
        else
            log_warning "No seed data found in database"
            log_info "Run migrations to add seed data: ./startup.sh --run-migrations"
        fi
    else
        log_info "Checking seed data via API..."
        local seed_urls=$(curl -s http://localhost:$API_PORT/api/urls | jq -r '.[] | select(.id | startswith("550e8400-e29b-41d4-a716-44665544000")) | .shortName' 2>/dev/null)
        
        if [ -n "$seed_urls" ]; then
            local count=$(echo "$seed_urls" | wc -l | tr -d ' ')
            log_success "Found $count seeded URL entries:"
            echo "$seed_urls" | sed 's/^/   • /'
        else
            log_warning "No seed data found"
            log_info "Run migrations to add seed data: ./startup.sh --run-migrations"
        fi
    fi
}

# Show help
show_help() {
    echo "🚀 ${PROJECT_NAME} Development Environment Manager"
    echo "========================================"
    echo ""
    echo "Usage: ./startup.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  --start-all              🚀 Start all services"
    echo "  --stop-all               🛑 Stop all services"
    echo "  --restart                🔄 Restart all services"
    echo "  --status                 🔍 Show status of all services"
    echo "  --db-status              🗄️ Show detailed database status and isolation"
    echo "  --restart-service <svc>  🔄 Restart specific service"
    echo "  --setup-hosts            🌐 Setup hosts file for '$GO_DOMAIN' domain"
    echo "  --remove-hosts           🗑️  Remove hosts file entry for '$GO_DOMAIN' domain"
    echo "  --check-hosts            ✅ Check if hosts file is configured"
    echo "  --generate-constants     📝 Generate Angular constants from environment"
    echo "  --generate-configs       ⚙️  Generate Angular configuration files from environment"
    echo ""
    echo "Database Management:"
    echo "  --run-migrations         🗄️ Run EF Core migrations (includes seed data)"
    echo "  --reset-database         🔄 Reset development database with fresh seed data"
    echo "  --check-seed-data        📊 Check if seed data is present in database"
    echo ""
    echo "  --help                   ❓ Show this help message"
    echo ""
    echo "Available services for --restart-service:"
    echo "  api, angular, nginx, postgres"
    echo ""
    echo "Examples:"
    echo "  ./startup.sh --start-all                    # Start everything"
    echo "  ./startup.sh --status                       # Check status"
    echo "  ./startup.sh --db-status                    # Check database isolation"
    echo "  ./startup.sh --restart-service angular      # Restart just Angular"
    echo "  ./startup.sh --setup-hosts                  # Configure hosts file"
    echo "  ./startup.sh --run-migrations               # Apply latest migrations & seed data"
    echo "  ./startup.sh --check-seed-data              # Verify seed data is present"
    echo "  ./startup.sh --reset-database               # Fresh database with seed data"
    echo "  ./startup.sh --stop-all                     # Stop everything"
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
    --db-status)
        show_database_status
        ;;
    --restart-service)
        if [ -z "${2:-}" ]; then
            log_error "Please specify a service to restart"
            echo "Available services: api, angular, nginx, postgres"
            exit 1
        fi
        restart_service "$2"
        ;;
    --setup-hosts)
        setup_hosts
        ;;
    --remove-hosts)
        remove_hosts_entry "$GO_DOMAIN"
        ;;
    --check-hosts)
        if check_hosts_entry "$GO_DOMAIN"; then
            log_success "Hosts entry for '$GO_DOMAIN' is configured"
            echo "  ✅ 127.0.0.1   $GO_DOMAIN"
        else
            log_warning "Hosts entry for '$GO_DOMAIN' is not configured"
            echo "  ❌ Missing: 127.0.0.1   $GO_DOMAIN"
            echo ""
            echo "Run: ./startup.sh --setup-hosts"
        fi
        ;;
    --generate-constants)
        log_header "📝 Generating Angular Constants"
        generate_angular_constants
        log_success "Angular constants generated successfully"
        ;;
    --generate-configs)
        log_header "📝 Generating Angular Configuration Files"
        generate_angular_constants
        generate_angular_configs
        log_success "Angular configuration files generated successfully"
        ;;
    --run-migrations)
        run_migrations
        ;;
    --reset-database)
        reset_database
        ;;
    --check-seed-data)
        check_seed_data
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