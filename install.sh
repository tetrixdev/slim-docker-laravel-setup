#!/bin/bash
set -e

# =============================================================================
# slim-docker-laravel-setup installer
#
# One-liner installation:
#   curl -sSL https://raw.githubusercontent.com/tetrixdev/slim-docker-laravel-setup/main/install.sh | bash
#
# This script is idempotent - run it to set up a new project or update an existing one.
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
REPO="tetrixdev/slim-docker-laravel-setup"
BRANCH="main"
TEMPLATE_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

# Detect mode
detect_mode() {
    if [ -f "www/artisan" ]; then
        echo "update"
    elif [ -f "artisan" ]; then
        echo "laravel-root"
    else
        echo "new"
    fi
}

# Clean infrastructure files (preserves www/ and .git/)
clean_infrastructure() {
    print_info "Cleaning existing infrastructure files..."

    # List of infrastructure files/folders to remove
    local infra_items=(
        "docker-laravel"
        "deploy"
        "compose.yml"
        ".env.example"
        "DOCKER_README.md"
        "setup.sh"
        ".github/workflows/docker-laravel.yml"
    )

    for item in "${infra_items[@]}"; do
        if [ -e "$item" ]; then
            rm -rf "$item"
            print_info "  Removed: $item"
        fi
    done

    print_success "Infrastructure cleaned"
}

# Download and extract template
download_template() {
    print_info "Downloading latest template from $REPO..."

    # Create temp directory
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Download and extract
    curl -sSL "$TEMPLATE_URL" | tar -xz -C "$tmp_dir"

    # Copy template files (excluding www/ to preserve existing)
    local template_dir="$tmp_dir/slim-docker-laravel-setup-$BRANCH/template"

    if [ ! -d "$template_dir" ]; then
        print_error "Template directory not found in downloaded archive"
        exit 1
    fi

    # Copy all template files except setup.sh (we'll handle that separately)
    for item in "$template_dir"/*; do
        local basename=$(basename "$item")
        if [ "$basename" != "setup.sh" ]; then
            cp -r "$item" .
        fi
    done

    # Copy hidden files (.github, etc.)
    for item in "$template_dir"/.*; do
        local basename=$(basename "$item")
        if [ "$basename" != "." ] && [ "$basename" != ".." ]; then
            cp -r "$item" .
        fi
    done

    # Copy setup.sh last
    cp "$template_dir/setup.sh" .
    chmod +x setup.sh

    print_success "Template files downloaded"
}

# Main installation logic
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       slim-docker-laravel-setup installer                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local mode=$(detect_mode)

    case "$mode" in
        "update")
            print_info "Mode: UPDATE (existing project detected in www/)"
            print_info "Your Laravel application in www/ will be preserved."
            echo ""

            # Clean old infrastructure
            clean_infrastructure

            # Download fresh template
            download_template

            print_success "Infrastructure updated to latest version!"
            echo ""
            print_info "Run ./setup.sh to reconfigure (or it will use existing settings)"
            ;;

        "laravel-root")
            print_info "Mode: NEW (Laravel project detected in current directory)"
            print_info "Your Laravel files will be moved to www/"
            echo ""

            # Download template first (setup.sh will move Laravel to www/)
            download_template

            print_success "Template downloaded!"
            echo ""
            print_info "Running setup..."
            echo ""

            # Run setup
            ./setup.sh "$@"
            ;;

        "new")
            print_info "Mode: NEW (empty directory)"
            print_warning "No Laravel project found. You need to:"
            echo ""
            print_info "  1. Create a Laravel project first:"
            print_info "     composer create-project laravel/laravel ."
            echo ""
            print_info "  2. Then run this installer again:"
            print_info "     curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
            echo ""
            print_info "  Or if you have an existing Laravel project elsewhere:"
            print_info "     mkdir www && cp -r /path/to/laravel/* www/"
            print_info "     curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
            exit 1
            ;;
    esac
}

# Run main with all arguments
main "$@"
