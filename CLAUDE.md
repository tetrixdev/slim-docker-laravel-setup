# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a Laravel Docker setup tool that creates containerized development and production environments. The system uses a **template-based approach** where placeholder values like `{{PROJECT_NAME}}` are replaced during setup.

### Core Components
- **Setup Script** (`setup.sh`): Main orchestrator that handles directory structure detection, template processing, and configuration
- **Shared Base Image** (`docker/shared/php/Dockerfile`): Common PHP 8.4-FPM image with PostgreSQL extensions, Composer, and Node.js 22 LTS
- **Environment-Specific Builds**: Development (`docker/local/`) and production (`docker/production/`) configurations that extend the shared base
- **Template System**: Files use `{{PLACEHOLDER}}` syntax for dynamic configuration replacement

### Container Stack
- **PHP-FPM**: PHP 8.4 with PostgreSQL, Zip extensions, Composer, Node.js
- **Nginx**: 1.29-alpine with Laravel-optimized routing
- **PostgreSQL**: 17-alpine with persistent storage and health checks

## Development Commands

**Setup and Initialization:**
```bash
# Run initial setup (interactive prompts for project name, production URL)
./setup.sh

# Start development environment
docker-compose up -d

# Check container status and health
docker-compose ps
```

**Laravel Operations (replace {PROJECT_NAME} with actual project name):**
```bash
# Database operations
docker-compose exec {PROJECT_NAME}-php php artisan migrate
docker-compose exec {PROJECT_NAME}-php php artisan migrate:fresh --seed
docker-compose exec {PROJECT_NAME}-php php artisan db:seed

# Laravel utilities
docker-compose exec {PROJECT_NAME}-php php artisan key:generate
docker-compose exec {PROJECT_NAME}-php php artisan tinker
docker-compose exec {PROJECT_NAME}-php php artisan optimize:clear
docker-compose exec {PROJECT_NAME}-php php artisan config:cache

# Queue management
docker-compose exec {PROJECT_NAME}-php php artisan queue:work
docker-compose exec {PROJECT_NAME}-php php artisan queue:restart
```

**Package Management:**
```bash
# Composer operations
docker-compose exec {PROJECT_NAME}-php composer install
docker-compose exec {PROJECT_NAME}-php composer update
docker-compose exec {PROJECT_NAME}-php composer dump-autoload -o

# NPM operations (Vite dev server runs automatically via entrypoint)
docker-compose exec {PROJECT_NAME}-php npm install
docker-compose exec {PROJECT_NAME}-php npm run build
docker-compose exec {PROJECT_NAME}-php npm run dev
```

**Debugging and Logs:**
```bash
# View logs
docker-compose logs -f {PROJECT_NAME}-php
docker-compose logs -f {PROJECT_NAME}-nginx
docker-compose logs -f {PROJECT_NAME}-postgres

# Container management
docker-compose restart {PROJECT_NAME}-php
docker-compose exec {PROJECT_NAME}-php bash
```

## Template Processing System

The setup script performs **in-place template substitution** on these files:
- `compose.yml`: Updates `{{PROJECT_NAME}}` and `{{LARAVEL_DIR}}` placeholders
- `.env.example` → `.env`: Updates `{{PROJECT_NAME}}` placeholders, generates secure DB password
- `docker/shared/nginx/default.conf`: Updates `{{PROJECT_NAME}}` for container references
- `docker/production/compose.yml`: Updates `{{PROJECT_NAME}}` and `{{GITHUB_REPOSITORY_OWNER}}`
- `docker/production/.env.example`: Updates `{{PROJECT_NAME}}` and `{{PRODUCTION_URL}}`

## Key Configuration Files

**Setup and Orchestration:**
- `setup.sh:132-271`: Main setup function with directory validation, user input, and template processing
- `setup.sh:34-102`: Directory structure validation (handles Laravel root vs prepared directory)

**Container Configuration:**
- `docker/local/php/entrypoint.sh:14-55`: Development container initialization sequence
- `docker/shared/php/Dockerfile:1-31`: Base PHP image with all required extensions and tools
- `docker/shared/nginx/default.conf`: Laravel-optimized Nginx configuration template

**Environment Management:**
- `.env.example:1-15`: Development environment template with placeholders
- `docker/production/.env.example`: Production environment template

## Automatic Setup Behaviors

**Vite Docker Configuration (`setup.sh:230-245`):**
- Detects existing `vite.config.js`
- Adds Docker-compatible server block: `host: '0.0.0.0'`, `hmr.host: 'localhost'`

**Directory Structure Handling (`setup.sh:37-60`):**
- **Laravel Root Detection**: If `artisan` exists, moves all files to `www/` folder
- **Prepared Directory**: Validates existing `www/` folder contains Laravel project

**Container Initialization (`docker/local/php/entrypoint.sh`):**
- Sets Laravel storage permissions (775/664)
- Generates APP_KEY if missing
- Creates storage symlink
- Installs npm dependencies and starts Vite dev server in background
- Runs composer install, migrations, and optimization commands

## Production Deployment Architecture

The setup creates a complete production deployment package in `docker/production/`:
- **Pre-built Images**: GitHub Actions workflow builds images on release tags
- **Multi-stage Builds**: Production PHP container optimized for runtime
- **Deployment Package**: Self-contained folder with compose file, environment template, and deployment guide

**Image Registry Pattern:**
- `ghcr.io/{GITHUB_REPOSITORY_OWNER}/{PROJECT_NAME}-php:latest`
- `ghcr.io/{GITHUB_REPOSITORY_OWNER}/{PROJECT_NAME}-nginx:latest`