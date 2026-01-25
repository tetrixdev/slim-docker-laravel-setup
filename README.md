# Laravel Docker Setup

A lightweight, production-ready Docker setup for Laravel applications with PHP 8.4-FPM, Nginx, and PostgreSQL.

## Features

- 🐘 **PHP 8.4-FPM** with PostgreSQL, Redis, Composer, and Node.js 22 LTS
- 🌐 **Nginx 1.27** optimized for Laravel
- 🗄️ **PostgreSQL 17** with persistent data storage
- 🔴 **Redis 7** for caching, sessions, and queues
- 🔥 **Vite Dev Server** with hot reload support (managed by Supervisor)
- ⚡ **Queue Worker** - `queue:listen` (dev) / `queue:work` (prod)
- 📅 **Scheduler** - `schedule:work` for sub-minute scheduling
- 🔧 **Health checks** for all services
- 📦 **One-command setup** for new and existing projects
- 🔄 **Configurable ports** for running multiple projects
- 🚀 **Production-ready** configuration

## New Project Setup

Create an empty folder with your desired project name, then copy and paste this:

```bash
# Install Laravel
composer create-project laravel/laravel www

# Download Docker setup
curl -L https://github.com/tetrixdev/slim-docker-laravel-setup/archive/main.tar.gz | tar -xz --wildcards --strip-components=2 "*/template/*"

# Run setup (will prompt for project name and production URL)
./setup.sh

# Start containers
docker compose up -d

# Your app is ready at http://localhost
```

## Setup Script Options

The setup script supports both interactive and non-interactive modes:

```bash
# Interactive setup (prompts for values)
./setup.sh

# Non-interactive setup with all parameters
./setup.sh -n myapp -u https://myapp.com -o myusername

# Auto-detect GitHub owner without prompting
./setup.sh -n myapp -u https://myapp.com -a

# Mixed: provide some parameters, prompt for others
./setup.sh -n myapp

# Available options:
#   -n, --project-name NAME     Set project name (lowercase, no spaces)
#   -u, --production-url URL    Set production URL for .env.production
#   -o, --github-owner OWNER    Set GitHub repository owner manually
#   -a, --auto-detect-owner     Auto-accept detected GitHub owner (no prompt)
#   -h, --help                  Show help message
#   --check                     Check prerequisites only
```

## Existing Project Setup

Navigate to your existing Laravel project root directory, then copy and paste this:

```bash
# Download Docker setup
curl -L https://github.com/tetrixdev/slim-docker-laravel-setup/archive/main.tar.gz | tar -xz --wildcards --strip-components=2 "*/template/*"

# Run setup (will automatically move Laravel files to www/ folder)
./setup.sh

# Start containers
docker compose up -d

# Your app is ready at http://localhost
```

## Local Development Testing

For testing this Docker setup locally during development:

### Setup Test Project
```bash
mkdir test-project

# Install Laravel
composer create-project laravel/laravel test-project/www

# Copy Docker setup from template directory
cp -r template/* template/.* test-project/ 2>/dev/null || cp -r template/* test-project/

# Or run non-interactive setup
(cd test-project ; ./setup.sh -n test-project -u https://test-project.com -o test-git-username)

# Start containers
(cd test-project ; docker compose up -d)
```

### Cleanup Test Environment
```bash
# Stop and remove containers, networks, and volumes
(cd test-project && docker compose down -v)

# Remove test project directory
sudo rm -rf test-project/
```

## Project Structure

After running setup, your project will have:

```
your-laravel-project/
├── .github/
│   └── workflows/
│       └── docker-build.yml    # GitHub Action for building production images
├── docker/                     # Docker configuration files
│   ├── local/                  # Local development files
│   │   └── php/
│   │       ├── Dockerfile      # Development PHP build
│   │       └── entrypoint.sh   # Development entrypoint
│   ├── shared/                 # Shared configuration files
│   │   ├── nginx/
│   │   │   └── default.conf    # Nginx configuration
│   │   └── php/
│   │       ├── Dockerfile      # Shared PHP base image
│   │       └── local.ini       # PHP configuration
│   └── production/             # Ready-to-deploy package
│   ├── nginx/
│   │   └── Dockerfile          # Production Nginx build
│   ├── php/
│   │   ├── Dockerfile          # Production PHP build
│   │   └── entrypoint.sh       # Production entrypoint
│   ├── README.md               # Production deployment guide
│   ├── compose.yml             # Production Docker Compose (uses pre-built images)
│   └── .env.example            # Production environment template
├── www/                        # Your Laravel application
│   ├── app/
│   ├── config/
│   └── ...
├── compose.yml                 # Development Docker Compose
├── .env                        # Current environment
└── .env.example                # Environment template
```

### File Purposes

- **Development files**: `docker/local/`, `compose.yml` - build locally for development
- **Shared configuration**: `docker/shared/` - shared base image and configuration files used by both environments
- **Production deployment**: `docker/production/` - ready-to-deploy package with instructions
- **CI/CD**: `.github/workflows/docker-build.yml` - builds production images on release

## Laravel Configuration

No Laravel configuration changes are required! The setup automatically handles:

- **Database configuration**: Uses environment variables that work with Laravel's default `config/database.php`
- **Vite configuration**: Automatically adds Docker-compatible server settings to `vite.config.js` for hot reload support

## Services

### PHP-FPM Container
- **Image**: Custom PHP 8.4-FPM
- **Extensions**: PDO, PostgreSQL, Zip
- **Tools**: Composer, Node.js 22 LTS, npm
- **Port**: 9000 (internal)
- **Vite Dev Server**: 5173

### Nginx Container
- **Image**: nginx:1.27-alpine
- **Port**: 80 (configurable via `NGINX_PORT`)
- **Configuration**: Optimized for Laravel

### PostgreSQL Container
- **Image**: postgres:17-alpine
- **Port**: 5433 external, 5432 internal (configurable via `DB_EXTERNAL_PORT`)
- **Data**: Persistent volume storage
- **Credentials**: Configurable via environment variables

### Redis Container
- **Image**: redis:7-alpine
- **Port**: 6379 (internal only)
- **Data**: Persistent volume storage
- **Use**: Caching, sessions, and queue backend

## Running Multiple Projects

To run multiple projects simultaneously, change the ports in `.env`:

```env
# Project A (defaults)
NGINX_PORT=80
VITE_PORT=5173
DB_EXTERNAL_PORT=5433

# Project B
NGINX_PORT=8080
VITE_PORT=5174
DB_EXTERNAL_PORT=5434
```

## Environment Variables

### Development (.env)
```env
APP_NAME=your-project
APP_ENV=local
APP_DEBUG=true
DB_CONNECTION=pgsql
DB_HOST=your-project-postgres
DB_DATABASE=your-project
DB_USERNAME=your-project
DB_PASSWORD=generated-secure-password

# Redis configuration
REDIS_HOST=your-project-redis
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Docker ports (change for multiple projects)
NGINX_PORT=80
VITE_PORT=5173
DB_EXTERNAL_PORT=5433
```

### Production (docker/production/.env.example)
```env
APP_NAME=your-project
APP_ENV=production
APP_DEBUG=false
DB_CONNECTION=pgsql
DB_HOST=your-project-postgres
DB_DATABASE=your-project
DB_USERNAME=your-project
DB_PASSWORD=CHANGE_THIS_PASSWORD
NGINX_PORT=80
```

## Usage Commands

### Start Services
```bash
docker compose up -d
```

### Stop Services
```bash
docker compose down
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f your-project-php
```

### Execute Commands in PHP Container
```bash
# Laravel Artisan
docker compose exec your-project-php php artisan migrate

# Composer
docker compose exec your-project-php composer install

# npm
docker compose exec your-project-php npm install
```

### Switch to Production
```bash
# Copy production environment
cp docker/production/.env.example .env
# Update database password to secure value
sed -i "s/CHANGE_THIS_PASSWORD/your-secure-password/" .env
docker compose restart
```

## Development Workflow

1. **Start development environment**:
   ```bash
   # .env is already set up for development
   docker compose up -d
   ```

2. **Install dependencies** (if needed):
   ```bash
   docker compose exec your-project-php composer install
   docker compose exec your-project-php npm install
   ```

3. **Run migrations**:
   ```bash
   docker compose exec your-project-php php artisan migrate
   ```

4. **Generate application key** (if needed):
   ```bash
   docker compose exec your-project-php php artisan key:generate
   ```

5. **Access your application** at `http://localhost`

## Architecture

### Container Stack
- **PHP Container**: PHP 8.4-FPM with Supervisor managing php-fpm, Vite, queue worker, and scheduler
- **Nginx Container**: nginx:1.27-alpine configured for Laravel routing
- **PostgreSQL Container**: postgres:17-alpine with persistent data storage
- **Redis Container**: redis:7-alpine for caching, sessions, and queues

### Supervisor-Managed Processes (in PHP container)
- `php-fpm` - PHP FastCGI Process Manager
- `npm-dev` - Vite dev server with HMR (local only)
- `queue-worker` - Laravel queue:listen (local) or queue:work (production)
- `scheduler` - Laravel schedule:work for sub-minute scheduling

### Container Networking
Services communicate via Docker's internal network:
- PHP-FPM: accessible internally on port 9000
- PostgreSQL: accessible internally on port 5432
- Redis: accessible internally on port 6379
- Nginx: exposed on configurable port (default 80)
- Vite dev server: exposed on configurable port (default 5173)

### Health Checks
All containers have health checks configured:
- PHP-FPM: `php-fpm -t`
- Nginx: `wget -q -O /dev/null http://localhost:80/`
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`

### Automated Container Initialization
The PHP container's entrypoint script automatically:
- Sets proper file permissions for Laravel storage
- Installs composer and npm dependencies
- Generates APP_KEY if missing
- Creates storage symlink
- Runs Laravel migrations and optimization commands
- Starts Supervisor (which manages php-fpm, Vite, queue, and scheduler)

### Data Persistence
PostgreSQL data is stored in a named Docker volume `postgres-data` for persistence across container restarts.

## Environment Management

### Switch Between Environments
```bash
# Switch to production
cp docker/production/.env.example .env
sed -i "s/CHANGE_THIS_PASSWORD/your-secure-password/" .env
docker compose restart

# Switch back to development
cp .env.example .env
sed -i "s/DB_PASSWORD=laravel/DB_PASSWORD=$(tr -dc 'A-Za-z0-9@#%^&*()_+-=' < /dev/urandom | head -c 32)/" .env
docker compose restart
```

## Production Deployment

The setup automatically creates a GitHub Action workflow that builds production-ready Docker images when you create releases.

### Automated Image Building

1. **Push your Laravel project to GitHub**
2. **Create a release** (tag like `v1.0.0`)
3. **GitHub Action automatically builds**:
   - `ghcr.io/your-username/your-project-php:v1.0.0` (Laravel app with dependencies)
   - `ghcr.io/your-username/your-project-nginx:v1.0.0` (Nginx with baked config)

### Production Deployment

The `docker/production/` folder contains everything needed for production deployment:

1. **Copy deployment package to server**:
   ```bash
   scp -r docker/production/ user@server:/path/to/deployment/
   cd /path/to/deployment/production/
   ```

2. **Configure production environment**:
   ```bash
   cp .env.example .env
   # Edit .env to set DB_PASSWORD and APP_URL
   nano .env
   ```

3. **Deploy using pre-built images**:
   ```bash
   # Deploy latest version
   docker compose up -d
   
   # Deploy specific version
   IMAGE_TAG=v1.0.0 docker compose up -d
   ```

3. **Production benefits**:
   - ✅ Fast deployments (no build time)
   - ✅ Dependencies pre-installed
   - ✅ Assets pre-built (no Node.js needed)
   - ✅ Optimized for production

## Troubleshooting

### Common Issues

**Laravel Storage Permissions:**
```bash
docker compose exec {PROJECT_NAME}-php chown -R www-data:www-data storage bootstrap/cache
docker compose exec {PROJECT_NAME}-php chmod -R 775 storage bootstrap/cache
```

**Database Connection Problems:**
- Check containers are running: `docker compose ps`
- Verify credentials in `.env` file
- Restart PostgreSQL: `docker compose restart {PROJECT_NAME}-postgres`

**Nginx 502 Bad Gateway:**
- Check PHP-FPM logs: `docker compose logs {PROJECT_NAME}-php`
- Restart PHP container: `docker compose restart {PROJECT_NAME}-php`

**Vite Development Server Issues:**
- Check Vite is running: `docker compose logs {PROJECT_NAME}-php | grep vite`
- Manually start: `docker compose exec {PROJECT_NAME}-php npm run dev`

## Advanced Configuration

### Custom PHP Configuration
Edit `docker/shared/php/local.ini` to customize PHP settings:
```ini
upload_max_filesize=40M
post_max_size=40M
memory_limit=256M
max_execution_time=120
```

### Custom Nginx Configuration
Edit `docker/shared/nginx/default.conf` for custom Nginx settings.

### Additional Services
Add services like Redis, Memcached, or Elasticsearch by extending the `compose.yml`.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a fresh Laravel installation
5. Submit a pull request

## License

This project is open-sourced software licensed under the MIT license.

## Support

For issues and questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review Docker and Laravel logs
- Open an issue on GitHub