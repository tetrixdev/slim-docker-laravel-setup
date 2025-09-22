# Laravel Docker Environment

This project uses Docker for local development and production deployment.

## Quick Start

```bash
# Start containers
docker compose up -d

# Check status
docker compose ps
```

## Daily Commands

### Laravel Commands
```bash
# Run migrations
docker compose exec {{PROJECT_NAME}}-php php artisan migrate

# Fresh migration with seeding
docker compose exec {{PROJECT_NAME}}-php php artisan migrate:fresh --seed

# Generate application key
docker compose exec {{PROJECT_NAME}}-php php artisan key:generate

# Clear all caches
docker compose exec {{PROJECT_NAME}}-php php artisan optimize:clear

# Run tinker
docker compose exec {{PROJECT_NAME}}-php php artisan tinker
```

### Package Management
```bash
# Install/update Composer dependencies
docker compose exec {{PROJECT_NAME}}-php composer install
docker compose exec {{PROJECT_NAME}}-php composer update

# Install/update NPM dependencies
docker compose exec {{PROJECT_NAME}}-php npm install
docker compose exec {{PROJECT_NAME}}-php npm update

# Build frontend assets
docker compose exec {{PROJECT_NAME}}-php npm run build
```

### Container Management
```bash
# View logs
docker compose logs -f {{PROJECT_NAME}}-php
docker compose logs -f {{PROJECT_NAME}}-nginx
docker compose logs -f {{PROJECT_NAME}}-postgres

# Restart containers
docker compose restart

# Stop containers
docker compose down

# Access PHP container shell
docker compose exec {{PROJECT_NAME}}-php bash
```

### Database Access
```bash
# Access PostgreSQL
docker compose exec {{PROJECT_NAME}}-postgres psql -U {{PROJECT_NAME}} -d {{PROJECT_NAME}}
```

## Environments

- **Local Development**: Uses `compose.yml` with hot-reload and debugging
- **Production**: See `docker-laravel/production/README.md` for deployment instructions

## Ports

- **Web**: http://localhost:8080
- **Vite Dev Server**: http://localhost:5173
- **PostgreSQL**: localhost:5432

## Troubleshooting

### Permission Issues
```bash
docker compose exec {{PROJECT_NAME}}-php chown -R www-data:www-data storage bootstrap/cache
```

### Container Won't Start
```bash
# Check logs for specific service
docker compose logs {{PROJECT_NAME}}-php
```

### Database Connection Failed
- Ensure `.env` has correct DB credentials
- Check if PostgreSQL container is healthy: `docker compose ps`

### Vite HMR Not Working
- Ensure port 5173 is not blocked
- Check Vite config includes Docker settings