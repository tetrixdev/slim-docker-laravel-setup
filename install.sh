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
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_cmd() { echo -e "${CYAN}   $1${NC}"; }

# Configuration
REPO="tetrixdev/slim-docker-laravel-setup"
BRANCH="main"
TEMPLATE_URL="https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"

# Detected values (populated in update mode)
DETECTED_PROJECT_NAME=""
DETECTED_GITHUB_OWNER=""
DETECTED_PRODUCTION_URL=""

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

# Detect existing configuration values (before wiping)
detect_existing_config() {
    print_info "Detecting existing configuration..."

    # Detect project name from compose.yml
    if [ -f "compose.yml" ]; then
        # Look for container_name: projectname-php pattern
        DETECTED_PROJECT_NAME=$(grep -oP 'container_name:\s*\K[^-\s]+' compose.yml 2>/dev/null | head -1)
        # Fallback: look for network name
        if [ -z "$DETECTED_PROJECT_NAME" ]; then
            DETECTED_PROJECT_NAME=$(grep -oP 'name:\s*\K[^-\s]+(?=-network)' compose.yml 2>/dev/null | head -1)
        fi
        # Skip if it's a template placeholder
        if [[ "$DETECTED_PROJECT_NAME" == *"{{"* ]]; then
            DETECTED_PROJECT_NAME=""
        fi
    fi

    # Detect GitHub owner from workflow file
    if [ -f ".github/workflows/docker-laravel.yml" ]; then
        DETECTED_GITHUB_OWNER=$(grep -oP 'ghcr\.io/\K[^/]+' .github/workflows/docker-laravel.yml 2>/dev/null | head -1)
        # Skip if it's a GitHub Actions variable (contains ${{ or }})
        if [[ "$DETECTED_GITHUB_OWNER" == *'${'* ]] || [[ "$DETECTED_GITHUB_OWNER" == *'}}'* ]]; then
            DETECTED_GITHUB_OWNER=""
        fi
    fi

    # Detect production URL from production .env.example
    if [ -f "docker-laravel/production/.env.example" ]; then
        DETECTED_PRODUCTION_URL=$(grep -oP 'APP_URL=\K.+' docker-laravel/production/.env.example 2>/dev/null | head -1)
        # Skip if still placeholder
        if [[ "$DETECTED_PRODUCTION_URL" == *"{{"* ]]; then
            DETECTED_PRODUCTION_URL=""
        fi
    fi

    # Fallback: detect from git remote
    if [ -z "$DETECTED_PROJECT_NAME" ] || [ -z "$DETECTED_GITHUB_OWNER" ]; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            local remote_url git_owner git_repo
            remote_url=$(git remote get-url origin 2>/dev/null)
            if [ -n "$remote_url" ]; then
                # Extract owner and repo from GitHub URL
                git_owner=$(echo "$remote_url" | sed -n 's#.*github\.com[:/]\([^/]*\)/.*#\1#p')
                git_repo=$(echo "$remote_url" | sed -n 's#.*github\.com[:/][^/]*/\([^.]*\).*#\1#p')

                if [ -z "$DETECTED_GITHUB_OWNER" ] && [ -n "$git_owner" ]; then
                    DETECTED_GITHUB_OWNER="$git_owner"
                fi
                if [ -z "$DETECTED_PROJECT_NAME" ] && [ -n "$git_repo" ]; then
                    DETECTED_PROJECT_NAME="$git_repo"
                fi
            fi
        fi
    fi

    # Report findings
    if [ -n "$DETECTED_PROJECT_NAME" ]; then
        print_info "  Project name: $DETECTED_PROJECT_NAME"
    fi
    if [ -n "$DETECTED_GITHUB_OWNER" ]; then
        print_info "  GitHub owner: $DETECTED_GITHUB_OWNER"
    fi
    if [ -n "$DETECTED_PRODUCTION_URL" ]; then
        print_info "  Production URL: $DETECTED_PRODUCTION_URL"
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
        fi
    done

    print_success "Infrastructure cleaned (www/ preserved)"
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

    # Write the commit hash for version tracking
    # This fetches the latest commit hash from the main branch
    local commit_hash
    commit_hash=$(curl -s "https://api.github.com/repos/$REPO/commits/$BRANCH" | grep -m1 '"sha"' | cut -d'"' -f4)
    if [ -n "$commit_hash" ]; then
        echo "$commit_hash" > .slim-docker-version
        print_success "Version tracking: $commit_hash"
    else
        print_warning "Could not fetch commit hash for version tracking"
    fi

    print_success "Template files downloaded"
}

# Output setup instructions with detected values
output_instructions() {
    local mode="$1"

    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"

    if [ "$mode" == "update" ]; then
        echo -e "${GREEN}  Infrastructure updated successfully!${NC}"
    else
        echo -e "${GREEN}  Template installed successfully!${NC}"
    fi

    echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Show detected values if any
    if [ -n "$DETECTED_PROJECT_NAME" ] || [ -n "$DETECTED_GITHUB_OWNER" ] || [ -n "$DETECTED_PRODUCTION_URL" ]; then
        print_info "Detected configuration:"
        [ -n "$DETECTED_PROJECT_NAME" ] && echo -e "   Project name:    ${CYAN}$DETECTED_PROJECT_NAME${NC}"
        [ -n "$DETECTED_GITHUB_OWNER" ] && echo -e "   GitHub owner:    ${CYAN}$DETECTED_GITHUB_OWNER${NC}"
        [ -n "$DETECTED_PRODUCTION_URL" ] && echo -e "   Production URL:  ${CYAN}$DETECTED_PRODUCTION_URL${NC}"
        echo ""
    fi

    # Instructions for running setup
    print_info "Next step - run setup to configure:"
    echo ""
    print_cmd "./setup.sh"
    echo ""

    # Build the non-interactive command with detected values
    local setup_cmd="./setup.sh"
    local has_params=false

    if [ -n "$DETECTED_PROJECT_NAME" ]; then
        setup_cmd="$setup_cmd -n \"$DETECTED_PROJECT_NAME\""
        has_params=true
    fi
    if [ -n "$DETECTED_PRODUCTION_URL" ]; then
        setup_cmd="$setup_cmd -u \"$DETECTED_PRODUCTION_URL\""
        has_params=true
    fi
    if [ -n "$DETECTED_GITHUB_OWNER" ]; then
        setup_cmd="$setup_cmd -o \"$DETECTED_GITHUB_OWNER\""
        has_params=true
    fi
    setup_cmd="$setup_cmd -a"

    print_info "For automation (non-interactive):"
    echo ""
    if [ "$has_params" = true ]; then
        print_cmd "$setup_cmd"
    else
        print_cmd "./setup.sh -n <project-name> -u <production-url> -o <github-owner> -a"
    fi
    echo ""

    # Git diff reminder for updates
    if [ "$mode" == "update" ]; then
        echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
        print_warning "After setup, review changes with git:"
        echo ""
        print_cmd "git diff"
        echo ""
        echo -e "   If you had manual customizations to docker configs (nginx,"
        echo -e "   Dockerfile, etc.), check if they need to be re-applied."
        echo -e "${YELLOW}────────────────────────────────────────────────────────────${NC}"
        echo ""
    fi
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
            echo ""

            # Detect existing values BEFORE cleaning
            detect_existing_config

            # Clean old infrastructure
            clean_infrastructure

            # Download fresh template
            download_template

            # Output instructions with detected values
            output_instructions "update"
            ;;

        "laravel-root")
            print_info "Mode: FRESH INSTALL (Laravel project detected)"
            print_info "Your Laravel files will be moved to www/"
            echo ""

            # Try to detect from git even for fresh install
            detect_existing_config

            # Download template (setup.sh will move Laravel to www/)
            download_template

            # Output instructions
            output_instructions "fresh"
            ;;

        "new")
            print_info "Mode: NEW (empty directory)"
            print_warning "No Laravel project found."
            echo ""
            print_info "Create a Laravel project first:"
            echo ""
            print_cmd "composer create-project laravel/laravel www"
            echo ""
            print_info "Then run this installer again:"
            echo ""
            print_cmd "curl -sSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash"
            echo ""
            exit 1
            ;;
    esac
}

# Run main
main "$@"
