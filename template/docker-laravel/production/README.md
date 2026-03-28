# Production Build & Deployment Guide

This folder contains the **Dockerfiles and configurations** used to build production images for **{{PROJECT_NAME}}**.

## Directory Structure

```text
docker-laravel/production/
├── nginx/
│   └── Dockerfile      # Production Nginx image
├── php/
│   ├── Dockerfile      # Production PHP-FPM image
│   ├── entrypoint.sh   # Container startup script
│   └── supervisor/     # Process management configs
├── .env.example        # Production environment template
└── README.md           # This file
```

## Building Images

Images are built automatically by GitHub Actions when you create a release. The workflow:

1. Builds `ghcr.io/{{GITHUB_REPOSITORY_OWNER}}/{{PROJECT_NAME}}-php:{tag}`
2. Builds `ghcr.io/{{GITHUB_REPOSITORY_OWNER}}/{{PROJECT_NAME}}-nginx:{tag}`
3. Pushes to GitHub Container Registry

To build manually:
```bash
# From project root
docker build -f docker-laravel/production/php/Dockerfile -t {{PROJECT_NAME}}-php .
docker build -f docker-laravel/production/nginx/Dockerfile -t {{PROJECT_NAME}}-nginx .
```

## Deployment

Production deployment uses the `deploy/` folder at the project root.

### Prerequisites

1. **Create the proxy network** (once per server):
   ```bash
   docker network create main-network
   ```

2. **Set up a reverse proxy** (e.g., [proxy-nginx](https://github.com/tetrixdev/proxy-nginx)):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/tetrixdev/proxy-nginx/main/install.sh | bash
   ```

### Deploy Steps

1. **Copy deploy folder to server**:
   ```bash
   scp -r deploy/ user@server:/path/to/{{PROJECT_NAME}}/
   ```

2. **Configure environment**:
   ```bash
   cd /path/to/{{PROJECT_NAME}}

   # Create .env from template
   cp docker-laravel/production/.env.example .env

   # Edit required values
   nano .env
   ```

3. **Set required environment variables**:
   ```bash
   export COMPOSE_PROJECT_NAME={{PROJECT_NAME}}
   export GITHUB_REPOSITORY_OWNER={{GITHUB_REPOSITORY_OWNER}}
   export DB_DATABASE={{PROJECT_NAME}}
   export DB_USERNAME={{PROJECT_NAME}}
   export DB_PASSWORD=your-secure-password
   ```

4. **Deploy**:
   ```bash
   docker compose -f deploy/compose.yml up -d
   ```

### Update Deployment

```bash
# Pull latest images and restart
docker compose -f deploy/compose.yml pull
docker compose -f deploy/compose.yml up -d

# Deploy specific version
IMAGE_TAG=v1.2.0 docker compose -f deploy/compose.yml up -d
```

## Environment Variables

See `.env.example` in this folder for the full list. Key variables:

| Variable | Description |
|----------|-------------|
| `APP_URL` | Your production domain (https://...) |
| `DB_PASSWORD` | Database password (change from default!) |
| `REDIS_HOST` | Redis container name (auto-set) |

## Proxy Configuration

The production compose joins `main-network`, allowing proxy-nginx to route traffic.

Add a server block to your proxy-nginx config:
```nginx
server {
    server_name {{PROJECT_NAME}}.yourdomain.com;

    location / {
        proxy_pass http://{{PROJECT_NAME}}-nginx;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    listen 80;
}
```

Then request SSL:
```bash
docker exec proxy-nginx certbot --nginx -d {{PROJECT_NAME}}.yourdomain.com
```

## Troubleshooting

**Container won't start:**
```bash
docker compose -f deploy/compose.yml logs php
docker compose -f deploy/compose.yml logs nginx
```

**Database connection issues:**
- Verify `DB_*` environment variables are set
- Check PostgreSQL is healthy: `docker compose -f deploy/compose.yml ps`

**Image pull failures:**
- Login to GHCR: `docker login ghcr.io`
- Verify image exists: `docker pull ghcr.io/{{GITHUB_REPOSITORY_OWNER}}/{{PROJECT_NAME}}-php:latest`
