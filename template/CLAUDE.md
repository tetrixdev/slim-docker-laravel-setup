# slim-docker-laravel-setup

Docker-based Laravel development and production environment.

## Version

Check `SLIM_DOCKER_VERSION` in `.env` or look for version comments in Dockerfiles.

## Structure

```text
docker-laravel/
├── local/           # Local development configs
│   ├── php/         # PHP Dockerfile, entrypoint, supervisor configs
│   └── (nginx uses shared config)
├── production/      # Production configs
│   ├── php/         # Production Dockerfile, entrypoint, supervisor configs
│   └── nginx/       # Production nginx Dockerfile
└── shared/          # Shared between local/production
    ├── nginx/       # Nginx config (default.conf)
    ├── php/         # PHP config (local.ini)
    └── supervisor/  # Main supervisord.conf

deploy/              # Production deployment
└── compose.yml      # Production compose file
```

## Containers

| Container | Local | Production | Purpose |
|-----------|-------|------------|---------|
| php | Build from Dockerfile | ghcr.io image | PHP-FPM + Vite (local) + Queue + Scheduler |
| nginx | nginx:1.27-alpine | ghcr.io image | Web server |
| postgres | postgres:17-alpine | postgres:17-alpine | Database |
| redis | redis:7-alpine | redis:7-alpine | Cache, sessions, queues |

## Key Differences: Local vs Production

| Aspect | Local | Production |
|--------|-------|------------|
| **Queue** | `queue:listen` (picks up code changes) | `queue:work` (efficient) |
| **Vite** | `npm run dev` via supervisor | Assets pre-built |
| **Logging** | stdout/stderr | Files in storage/logs |
| **Workers** | 1 queue worker | 2 queue workers |

## Port Configuration

All ports configurable via `.env`:
- `NGINX_PORT` - Web server (default: 80)
- `VITE_PORT` - Vite HMR (default: 5173)
- `DB_EXTERNAL_PORT` - PostgreSQL external (default: 5433, internal always 5432)

Change these when running multiple projects simultaneously.

## Vite HMR Configuration

The `vite.config.js` reads `APP_URL` to configure HMR for external/mobile access:
- `APP_URL=http://localhost` - HMR works only on localhost
- `APP_URL=http://192.168.1.100` - HMR works from any device on the network

This enables testing on mobile devices during development.

## Supervisor Processes

Local dev runs via supervisor (PID 1):
- `php-fpm` - PHP FastCGI Process Manager
- `npm-dev` - Vite dev server with HMR
- `queue-worker` - Laravel queue:listen
- `scheduler` - Laravel schedule:work

Production runs via supervisor:
- `php-fpm` - PHP FastCGI Process Manager
- `queue-worker` - Laravel queue:work (x2)
- `scheduler` - Laravel schedule:work

## Updating from slim-docker-laravel-setup

1. Check current version: `grep SLIM_DOCKER_VERSION .env`
2. Read CHANGELOG.md for versions between current and target
3. Apply changes, noting any conflicts with customizations
4. Update version in `.env`

## Customizable vs Template Files

**Template files** (update from upstream):
- `docker-laravel/**/*` - Docker configs
- `.github/workflows/docker-laravel.yml` - Build workflow

**Customizable files** (merge carefully):
- `compose.yml` - May have project-specific services
- `.env.example` - May have project-specific vars
- `vite.config.js` - May have additional plugins

## Common Tasks

### Add a PHP extension
Edit both Dockerfiles:
- `docker-laravel/local/php/Dockerfile`
- `docker-laravel/production/php/Dockerfile`

### Change queue worker count
Edit `docker-laravel/production/php/supervisor/queue-work.conf`:
```ini
numprocs=4  # Change from 2 to 4
```

### Disable scheduler
Remove or rename `schedule-work.conf` in supervisor directory.

### Database backup
```bash
docker compose exec {{PROJECT_NAME}}-php pg_dump -h {{PROJECT_NAME}}-postgres -U {{PROJECT_NAME}} {{PROJECT_NAME}} > backup.sql
```
