#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    read -p "$prompt [$default]: " result
    echo "${result:-$default}"
}

# Main setup function
setup_laravel_docker() {
    print_info "🚀 Laravel Docker Setup"
    echo ""
    
    # Get project details from user
    PROJECT_NAME=$(get_input "Enter your project name (lowercase, no spaces)" "mylaravel")
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    
    LARAVEL_DIR=$(get_input "Enter Laravel directory name (relative to current dir)" "www")
    PRODUCTION_URL=$(get_input "Enter production URL (for .env.production)" "https://example.com")
    
    # Validate Laravel directory exists
    if [ ! -d "$LARAVEL_DIR" ]; then
        print_error "Laravel directory '$LARAVEL_DIR' does not exist in current directory"
        print_info "Please ensure your Laravel project is in the '$LARAVEL_DIR' folder"
        exit 1
    fi
    
    # Check if Laravel project has required files
    if [ ! -f "$LARAVEL_DIR/artisan" ]; then
        print_error "No 'artisan' file found in '$LARAVEL_DIR'. Are you sure this is a Laravel project?"
        exit 1
    fi
    
    print_info "Setting up Docker configuration for project: $PROJECT_NAME"
    
    # Copy docker directory if it doesn't exist
    if [ ! -d "docker" ]; then
        print_info "Copying Docker configuration files..."
        cp -r "$(dirname "$0")/docker" .
        print_success "Docker configuration copied"
    else
        print_warning "Docker directory already exists, skipping copy"
    fi
    
    # Process compose.yml template
    print_info "Creating docker-compose.yml..."
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{LARAVEL_DIR}}/$LARAVEL_DIR/g" \
        "$(dirname "$0")/compose.yml.template" > compose.yml
    print_success "docker-compose.yml created"
    
    # Process nginx template
    print_info "Updating nginx configuration..."
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        "$(dirname "$0")/docker/nginx/default.conf" > docker/nginx/default.conf
    print_success "Nginx configuration updated"
    
    # Create environment files
    print_info "Creating .env files..."
    
    # Development environment
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
        "$(dirname "$0")/.env.dev.template" > .env.dev
    
    # Production environment  
    sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s|{{PRODUCTION_URL}}|$PRODUCTION_URL|g" \
        "$(dirname "$0")/.env.production.template" > .env.production
    
    # Copy development environment as default
    cp .env.dev .env
    
    print_success "Environment files created (.env, .env.dev, .env.production)"
    
    # Update Laravel database configuration
    update_laravel_config
    
    print_success "🎉 Setup completed successfully!"
    print_info ""
    print_info "Next steps:"
    print_info "1. Run: docker-compose up -d"
    print_info "2. Your Laravel app will be available at: http://localhost"
    print_info "3. To switch environments: cp .env.production .env (then restart containers)"
    print_info ""
    print_info "Database connection details:"
    print_info "  Host: $PROJECT_NAME-postgres"
    print_info "  Database: $PROJECT_NAME"
    print_info "  Username: $PROJECT_NAME"
    print_info "  Password: laravel"
}

# Function to update Laravel database configuration
update_laravel_config() {
    local db_config="$LARAVEL_DIR/config/database.php"
    
    if [ ! -f "$db_config" ]; then
        print_warning "Laravel database config not found, skipping automatic update"
        return
    fi
    
    print_info "Updating Laravel database configuration..."
    
    # Backup original config
    cp "$db_config" "$db_config.backup"
    
    # Update database configuration
    sed -i "s/'default' => env('DB_CONNECTION', '[^']*')/'default' => env('DB_CONNECTION', 'pgsql')/g" "$db_config"
    sed -i "s/'host' => env('DB_HOST', '[^']*')/'host' => env('DB_HOST', '$PROJECT_NAME-postgres')/g" "$db_config"
    sed -i "s/'database' => env('DB_DATABASE', '[^']*')/'database' => env('DB_DATABASE', '$PROJECT_NAME')/g" "$db_config"
    sed -i "s/'username' => env('DB_USERNAME', '[^']*')/'username' => env('DB_USERNAME', '$PROJECT_NAME')/g" "$db_config"
    
    print_success "Laravel database configuration updated (backup saved as database.php.backup)"
}

# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --check        Check prerequisites only"
    echo ""
    echo "This script sets up Laravel with Docker (PHP 8.4-FPM + Nginx + PostgreSQL)"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    --check)
        check_prerequisites
        exit 0
        ;;
    "")
        # No arguments, proceed with setup
        ;;
    *)
        print_error "Unknown option: $1"
        usage
        exit 1
        ;;
esac

# Run the setup
check_prerequisites
setup_laravel_docker