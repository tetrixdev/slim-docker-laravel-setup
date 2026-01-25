#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Command line parameter variables
PARAM_PROJECT_NAME=""
PARAM_PRODUCTION_URL=""
PARAM_GITHUB_OWNER=""
PARAM_AUTO_DETECT=false

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

# Function to validate and prepare directory structure
validate_directory() {
    print_info "Validating directory structure..."
    
    # Case 1: Check if we're in an existing Laravel project root
    if [ -f "artisan" ]; then
        print_info "Detected existing Laravel project. Moving files to www/ folder..."
        
        # Create www directory
        mkdir -p www
        
        # Move all files except www to www/ folder (handle setup files gracefully)
        for item in *; do
            if [ "$item" != "www" ] && [ "$item" != "setup.sh" ] && [ "$item" != "compose.yml.template" ] && [ "$item" != "docker-laravel" ] && [ "$item" != ".env.example" ]; then
                mv "$item" www/
            fi
        done
        
        # Move hidden files too (like .env, .git, etc.)
        for item in .*; do
            if [ "$item" != "." ] && [ "$item" != ".." ] && [ -e "$item" ]; then
                mv "$item" www/
            fi
        done
        
        print_success "Laravel project moved to www/ folder"
        return
    fi
    
    # Case 2: Check if we're in a prepared directory with www/ folder
    if [ -d "www" ]; then
        # Check if Laravel project has required files
        if [ ! -f "www/artisan" ]; then
            print_error "No 'artisan' file found in 'www/'. Are you sure this is a Laravel project?"
            exit 1
        fi
        
        # Check for unexpected files (allow setup files and www folder)
        visible_files=$(ls -1 2>/dev/null | wc -l)
        if [ "$visible_files" -gt 0 ]; then
            allowed_files="www setup.sh compose.yml docker-laravel .env.example DOCKER_README.md .github"
            for file in *; do
                if [ -e "$file" ]; then
                    case " $allowed_files " in
                        *" $file "*) ;;
                        *) 
                            print_error "Unexpected file/folder found: $file"
                            print_info "Expected: empty directory with 'www/' folder containing Laravel"
                            exit 1
                            ;;
                    esac
                fi
            done
        fi
        
        print_success "Directory structure validation passed"
        return
    fi
    
    # Case 3: Neither Laravel root nor prepared directory
    print_error "Invalid directory structure detected"
    print_info ""
    print_info "This setup script expects one of:"
    print_info "  1. Laravel project root (with 'artisan' file) - will move to www/"
    print_info "  2. Empty directory with 'www/' folder containing Laravel"
    print_info ""
    print_info "Current directory contents:"
    ls -la
    exit 1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists docker-compose && ! docker compose version &>/dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local provided="$3"
    local result

    # If a value was provided via command line, use it
    if [[ -n "$provided" ]]; then
        echo "$provided"
        return
    fi

    # Otherwise, prompt the user
    read -p "$prompt [$default]: " result
    echo "${result:-$default}"
}

# Main setup function
setup_laravel_docker() {
    print_info "🚀 Laravel Docker Setup"
    echo ""
    
    # Validate directory structure first
    validate_directory
    
    # Set Laravel directory (always "www" now)
    LARAVEL_DIR="www"
    
    # Get project details from user
    PROJECT_NAME=$(get_input "Enter your project name (lowercase, no spaces)" "mylaravel" "$PARAM_PROJECT_NAME")
    PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')

    PRODUCTION_URL=$(get_input "Enter production URL (for .env.production)" "https://example.com" "$PARAM_PRODUCTION_URL")
    
    # Determine GitHub repository owner
    if [[ -n "$PARAM_GITHUB_OWNER" ]]; then
        # Use manually provided GitHub owner (highest priority)
        GITHUB_REPOSITORY_OWNER="$PARAM_GITHUB_OWNER"
        print_info "Using provided GitHub repository owner: $GITHUB_REPOSITORY_OWNER"
    else
        # Try to auto-detect GitHub repository owner
        DETECTED_OWNER=""
        if git rev-parse --git-dir > /dev/null 2>&1; then
            # Try git remote first
            DETECTED_OWNER=$(git remote get-url origin 2>/dev/null | sed -n 's#.*github\.com[:/]\([^/]*\)/.*#\1#p')
            if [ -z "$DETECTED_OWNER" ]; then
                # Fall back to git config user name
                DETECTED_OWNER=$(git config user.name 2>/dev/null)
            fi
        fi

        # Handle auto-detection results
        if [[ -n "$DETECTED_OWNER" ]]; then
            print_info "Auto-detected GitHub repository owner: $DETECTED_OWNER"

            if [[ "$PARAM_AUTO_DETECT" == true ]]; then
                # Auto-accept detected owner without prompting
                GITHUB_REPOSITORY_OWNER="$DETECTED_OWNER"
                print_info "Auto-accepting detected owner: $GITHUB_REPOSITORY_OWNER"
            else
                # Ask user about using detected owner
                USE_DETECTED=$(get_input "Use auto-detected owner for container registry? (yes/no)" "yes")
                if [[ "$USE_DETECTED" =~ ^[Yy]([Ee][Ss])?$ ]]; then
                    GITHUB_REPOSITORY_OWNER="$DETECTED_OWNER"
                else
                    GITHUB_REPOSITORY_OWNER=$(get_input "Enter GitHub repository owner manually" "${DETECTED_OWNER}")
                fi
            fi
        else
            # No auto-detection possible
            if [[ "$PARAM_AUTO_DETECT" == true ]]; then
                print_warning "Auto-detect requested but no GitHub repository detected. Falling back to interactive prompt."
            fi
            GITHUB_REPOSITORY_OWNER=$(get_input "Enter GitHub repository owner (for container registry)" "$(whoami)")
        fi
    fi
    
    # Process compose.yml template
    print_info "Processing docker-compose.yml..."
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{LARAVEL_DIR}}/$LARAVEL_DIR/g" compose.yml
    print_success "docker-compose.yml configured"
    
    # Process nginx template
    print_info "Updating nginx configuration..."
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" docker-laravel/shared/nginx/default.conf
    print_success "Nginx configuration updated"
    
    # Copy and process GitHub Action workflow
    print_info "Setting up GitHub Action workflow..."
    # .github directory is already at template root, no need to copy from docker/local
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{GITHUB_REPOSITORY_OWNER}}/$GITHUB_REPOSITORY_OWNER/g" .github/workflows/docker-laravel.yml
    print_success "GitHub Action workflow configured"
    
    # Process production compose file
    print_info "Processing production docker-compose file..."
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{GITHUB_REPOSITORY_OWNER}}/$GITHUB_REPOSITORY_OWNER/g" docker-laravel/production/compose.yml
    print_success "docker-laravel/production/compose.yml processed"
    
    # Create environment files
    print_info "Creating .env files..."
    
    # Update .env.example with project-specific values
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .env.example
    
    # Create .env from .env.example with generated password
    cp .env.example .env
    sed -i "s/DB_PASSWORD=laravel/DB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)/" .env

    # Process docker-laravel/production/.env.example
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" docker-laravel/production/.env.example
    sed -i "s#{{PRODUCTION_URL}}#$PRODUCTION_URL#g" docker-laravel/production/.env.example
    sed -i "s/DB_PASSWORD=laravel/DB_PASSWORD=CHANGE_THIS_PASSWORD/" docker-laravel/production/.env.example
    
    # Process production deployment README
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; s/{{GITHUB_REPOSITORY_OWNER}}/$GITHUB_REPOSITORY_OWNER/g" docker-laravel/production/README.md

    # Process Docker README
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" DOCKER_README.md

    print_success "Production deployment package created in docker-laravel/production/"
    
    # Configure Vite for Docker if needed
    if [ -f "$LARAVEL_DIR/vite.config.js" ]; then
        print_info "Configuring Vite for Docker..."
        if ! grep -q "server:" "$LARAVEL_DIR/vite.config.js"; then
            # Add server configuration for Docker before the closing brace
            sed -i '/^});$/i\    server: {\
        host: '\''0.0.0.0'\'',\
        port: 5173,\
        hmr: {\
            host: '\''localhost'\'',\
        },\
    },' "$LARAVEL_DIR/vite.config.js"
            print_success "Vite configured for Docker (server block added)"
        else
            print_info "Vite server configuration already exists, skipping"
        fi
    fi
    
    # Clean up setup script after successful completion
    print_info "Cleaning up setup files..."
    rm -f setup.sh
    print_success "Setup script removed"
    
    # Note: Laravel database configuration is handled via environment variables
    
    print_success "🎉 Setup completed successfully!"
    print_info ""
    print_info "Development setup:"
    print_info "1. Run: docker-compose up -d"
    print_info "2. Your Laravel app will be available at: http://localhost"
    print_info ""
    print_info "Production deployment:"
    print_info "1. Create GitHub release to trigger image build"
    print_info "2. Deploy with: cd docker-laravel/production && docker-compose up -d"
    print_info "3. Use built images: ghcr.io/$GITHUB_REPOSITORY_OWNER/$PROJECT_NAME-php:latest"
    print_info ""
    print_info "Database connection details:"
    print_info "  Host: $PROJECT_NAME-postgres"
    print_info "  Database: $PROJECT_NAME"
    print_info "  Username: $PROJECT_NAME"
    print_info "  Password: [auto-generated for development]"
}


# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script sets up Laravel with Docker (PHP 8.4-FPM + Nginx + PostgreSQL)"
    echo ""
    echo "Options:"
    echo "  -n, --project-name NAME     Set project name (lowercase, no spaces)"
    echo "  -u, --production-url URL    Set production URL for .env.production"
    echo "  -o, --github-owner OWNER    Set GitHub repository owner manually"
    echo "  -a, --auto-detect-owner     Auto-accept detected GitHub owner (no prompt)"
    echo "  -h, --help                  Show this help message"
    echo "  --check                     Check prerequisites only"
    echo ""
    echo "Examples:"
    echo "  # Interactive setup (default behavior)"
    echo "  $0"
    echo ""
    echo "  # Fully non-interactive setup"
    echo "  $0 -n myapp -u https://myapp.com -o myusername"
    echo ""
    echo "  # Auto-detect GitHub owner without prompting"
    echo "  $0 -n myapp -u https://myapp.com -a"
    echo ""
    echo "  # Mixed: provide some parameters, prompt for others"
    echo "  $0 -n myapp"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--project-name)
            if [[ -n "$2" && "$2" != -* ]]; then
                PARAM_PROJECT_NAME="$2"
                shift 2
            else
                print_error "Option $1 requires a value"
                exit 1
            fi
            ;;
        -u|--production-url)
            if [[ -n "$2" && "$2" != -* ]]; then
                PARAM_PRODUCTION_URL="$2"
                shift 2
            else
                print_error "Option $1 requires a value"
                exit 1
            fi
            ;;
        -o|--github-owner)
            if [[ -n "$2" && "$2" != -* ]]; then
                PARAM_GITHUB_OWNER="$2"
                shift 2
            else
                print_error "Option $1 requires a value"
                exit 1
            fi
            ;;
        -a|--auto-detect-owner)
            PARAM_AUTO_DETECT=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --check)
            check_prerequisites
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            print_error "Unexpected argument: $1"
            usage
            exit 1
            ;;
    esac
done

# Run the setup
check_prerequisites
setup_laravel_docker