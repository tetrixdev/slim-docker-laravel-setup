# Changelog

All notable changes to slim-docker-laravel-setup will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-25

### Added
- **Redis container** for cache, sessions, and queues (local + production)
- **Supervisor integration** - php-fpm, queue workers, and scheduler all managed by supervisor
- **Queue worker** using `queue:listen` (local) and `queue:work` (production)
- **Scheduler** using `schedule:work` for sub-minute scheduling support
- **Vite dev server** managed by supervisor for reliable HMR
- **Configurable ports** via .env:
  - `NGINX_PORT` (default: 80)
  - `VITE_PORT` (default: 5173)
  - `DB_EXTERNAL_PORT` (default: 5433 - different from internal 5432)
- **UTF-8 locale support** in PHP containers
- **PostgreSQL 17 client tools** (pg_dump, pg_restore) for database operations
- **Redis PHP extension** for native Redis support
- **Pre-build optimization** in GitHub Actions workflow
- **Prerelease handling** - `:latest` tag only updated for full releases
- **Named volumes and networks** for easier identification
- **Production compose file** at `deploy/compose.yml`
- **CLAUDE.md** for AI-assisted development and updates
- **Version tracking** in .env (SLIM_DOCKER_VERSION)
- This CHANGELOG

### Changed
- **Entrypoint architecture** - Now uses supervisor as PID 1 instead of php-fpm
- **Vite handling** - Managed by supervisor instead of background process in entrypoint
- **.env.example** now includes:
  - Redis configuration (REDIS_HOST, CACHE_DRIVER, SESSION_DRIVER, QUEUE_CONNECTION)
  - Docker configuration section with port settings
- **GitHub Actions workflow** - Pre-builds composer/npm in runner for better caching
- **Nginx image** - Updated to 1.27-alpine (was 1.29-alpine which doesn't exist)
- **Volume mounts** - Added `:ro` for read-only mounts where appropriate

### Fixed
- Nginx image tag (1.29-alpine doesn't exist, now using 1.27-alpine)
- Workflow Dockerfile paths (was `docker/production`, now `docker-laravel/production`)

## Migration Guide

### From previous versions to 0.1.0

1. **Add new files:**
   ```text
   docker-laravel/shared/supervisor/supervisord.conf
   docker-laravel/local/php/supervisor/*.conf
   docker-laravel/production/php/supervisor/*.conf
   deploy/compose.yml
   CLAUDE.md
   ```

2. **Update Dockerfiles** with new packages:
   - `supervisor`, `ca-certificates`, `locales`
   - PostgreSQL 17 client
   - Redis PHP extension
   - UTF-8 locale configuration

3. **Update .env with new variables:**
   ```env
   REDIS_HOST={{PROJECT_NAME}}-redis
   REDIS_PASSWORD=null
   REDIS_PORT=6379
   CACHE_DRIVER=redis
   SESSION_DRIVER=redis
   QUEUE_CONNECTION=redis
   DB_EXTERNAL_PORT=5433
   ```

4. **Update compose.yml:**
   - Add redis service
   - Add supervisor volume mounts
   - Update port variable names
   - Add named volumes and networks

5. **Update entrypoint.sh:**
   - Remove Vite background process handling
   - Add supervisor startup at the end

6. **Rebuild containers:**
   ```bash
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```
