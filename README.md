# Laravel Docker Setup

A lightweight, production-ready Docker setup for Laravel applications with PHP 8.4-FPM, Nginx, and PostgreSQL.

## Features

- 🐘 **PHP 8.4-FPM** with PostgreSQL, Composer, and Node.js 22 LTS
- 🌐 **Nginx 1.29** optimized for Laravel
- 🐘 **PostgreSQL 17** with persistent data storage
- 🔥 **Vite Dev Server** with hot reload support
- 🔧 **Health checks** for all services
- 📦 **Automated setup** with customizable project names
- 🔄 **Environment management** (development/production)
- 🚀 **Production-ready** configuration

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Composer installed (for creating Laravel projects)

### Automated Setup (Recommended)

1. **Create new project folder and Laravel installation**:
   ```bash
   mkdir new-project-folder
   cd new-project-folder
   composer create-project laravel/laravel www
   ```

2. **Download and extract Docker setup files**:
   ```bash
   curl -L https://github.com/tetrixdev/slim-docker-laravel-setup/archive/main.tar.gz | tar -xz --strip-components=1
   ```

3. **Run the automated setup**:
   ```bash
   ./setup.sh
   ```
   - Enter your project name (e.g., "myapp")
   - Enter Laravel directory: "www"
   - Enter production URL (e.g., "https://myapp.com")

4. **Start the containers**:
   ```bash
   docker-compose up -d
   ```

5. **Access your application** at `http://localhost`

### Manual Setup

If you prefer to set up manually:

1. **Copy files to your Laravel project**:
   ```bash
   # Copy Docker configuration
   cp -r docker/ /path/to/your/laravel/project/
   cp compose.yml.template /path/to/your/laravel/project/compose.yml
   ```

2. **Edit `compose.yml`**:
   - Replace `{{PROJECT_NAME}}` with your project name (e.g., `myapp`)
   - Replace `{{LARAVEL_DIR}}` with your Laravel directory (e.g., `www` or `.`)

3. **Edit `docker/nginx/default.conf`**:
   - Replace `{{PROJECT_NAME}}` with your project name

4. **Create environment files**:
   ```bash
   # Copy and customize environment templates
   cp .env.dev.template .env.dev
   cp .env.production.template .env.production
   cp .env.dev .env
   ```
   - Replace `{{PROJECT_NAME}}` with your project name
   - Update `{{PRODUCTION_URL}}` in `.env.production`

5. **Update Laravel database configuration** (see [Laravel Configuration](#laravel-configuration))

6. **Start containers**:
   ```bash
   docker-compose up -d
   ```

## Project Structure

```
your-laravel-project/
├── docker/
│   ├── nginx/
│   │   └── default.conf        # Nginx configuration
│   └── php/
│       ├── Dockerfile          # PHP 8.4-FPM with extensions
│       ├── entrypoint.sh       # Container initialization script
│       └── local.ini           # PHP configuration
├── www/                        # Your Laravel application
│   ├── app/
│   ├── config/
│   └── ...
├── compose.yml                 # Docker Compose configuration
├── .env                        # Current environment
├── .env.dev                    # Development environment
├── .env.production             # Production environment
└── setup.sh                   # Automated setup script
```

## Laravel Configuration

The setup requires minimal changes to your Laravel configuration:

### Database Configuration

Update `config/database.php` (automatically done by setup script):

```php
// Change default connection
'default' => env('DB_CONNECTION', 'pgsql'),

// Update PostgreSQL configuration
'pgsql' => [
    'driver' => 'pgsql',
    'url' => env('DB_URL'),
    'host' => env('DB_HOST', 'your-project-postgres'),  // Use your project name
    'port' => env('DB_PORT', '5432'),
    'database' => env('DB_DATABASE', 'your-project'),   // Use your project name
    'username' => env('DB_USERNAME', 'your-project'),   // Use your project name
    'password' => env('DB_PASSWORD', ''),
    // ... rest of configuration
],
```

## Services

### PHP-FPM Container
- **Image**: Custom PHP 8.4-FPM
- **Extensions**: PDO, PostgreSQL, Zip
- **Tools**: Composer, Node.js 22 LTS, npm
- **Port**: 9000 (internal)
- **Vite Dev Server**: 5173

### Nginx Container
- **Image**: nginx:1.29-alpine
- **Port**: 80 (configurable via `NGINX_PORT`)
- **Configuration**: Optimized for Laravel

### PostgreSQL Container
- **Image**: postgres:17-alpine
- **Port**: 5432 (configurable via `DB_PORT`)
- **Data**: Persistent volume storage
- **Credentials**: Configurable via environment variables

## Environment Variables

### Development (.env.dev)
```env
APP_NAME=your-project
APP_ENV=local
APP_DEBUG=true
DB_CONNECTION=pgsql
DB_HOST=your-project-postgres
DB_DATABASE=your-project
DB_USERNAME=your-project
DB_PASSWORD=laravel
NGINX_PORT=80
VITE_PORT=5173
```

### Production (.env.production)
```env
APP_NAME=your-project
APP_ENV=production
APP_DEBUG=false
DB_CONNECTION=pgsql
DB_HOST=your-project-postgres
DB_DATABASE=your-project
DB_USERNAME=your-project
DB_PASSWORD=laravel
NGINX_PORT=80
```

## Usage Commands

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f your-project-php
```

### Execute Commands in PHP Container
```bash
# Laravel Artisan
docker-compose exec your-project-php php artisan migrate

# Composer
docker-compose exec your-project-php composer install

# npm
docker-compose exec your-project-php npm install
```

### Switch Environments
```bash
# Switch to production
cp .env.production .env
docker-compose restart

# Switch to development
cp .env.dev .env
docker-compose restart
```

## Development Workflow

1. **Start development environment**:
   ```bash
   cp .env.dev .env
   docker-compose up -d
   ```

2. **Install dependencies** (if needed):
   ```bash
   docker-compose exec your-project-php composer install
   docker-compose exec your-project-php npm install
   ```

3. **Run migrations**:
   ```bash
   docker-compose exec your-project-php php artisan migrate
   ```

4. **Generate application key** (if needed):
   ```bash
   docker-compose exec your-project-php php artisan key:generate
   ```

5. **Access your application** at `http://localhost`

## Production Deployment

1. **Switch to production environment**:
   ```bash
   cp .env.production .env
   ```

2. **Update production URL** in `.env`:
   ```env
   APP_URL=https://your-domain.com
   ```

3. **Update database password** for security:
   ```env
   DB_PASSWORD=your-secure-password
   ```

4. **Deploy with production settings**:
   ```bash
   docker-compose up -d --build
   ```

## Troubleshooting

### Permission Issues
```bash
# Fix Laravel storage permissions
docker-compose exec your-project-php chown -R www-data:www-data storage bootstrap/cache
docker-compose exec your-project-php chmod -R 775 storage bootstrap/cache
```

### Database Connection Issues
- Ensure PostgreSQL container is running: `docker-compose ps`
- Check database credentials in `.env`
- Verify Laravel `config/database.php` settings

### Nginx 502 Bad Gateway
- Check if PHP-FPM container is running: `docker-compose logs your-project-php`
- Verify PHP-FPM is listening on port 9000

### Vite/Asset Issues
- Check if Vite is running: `docker-compose logs your-project-php | grep vite`
- Verify `VITE_PORT` in environment file
- Run `npm run dev` manually if needed

## Advanced Configuration

### Custom PHP Configuration
Edit `docker/php/local.ini` to customize PHP settings:
```ini
upload_max_filesize=40M
post_max_size=40M
memory_limit=256M
max_execution_time=120
```

### Custom Nginx Configuration
Edit `docker/nginx/default.conf` for custom Nginx settings.

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