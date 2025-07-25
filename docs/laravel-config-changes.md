# Laravel Configuration Changes

This document details the specific changes needed to configure Laravel for this Docker setup.

## Required Changes

### 1. Database Configuration (`config/database.php`)

The following changes are required in your Laravel `config/database.php` file:

#### Change Default Database Connection

```php
// Before (typical Laravel default)
'default' => env('DB_CONNECTION', 'sqlite'),

// After (for Docker setup)
'default' => env('DB_CONNECTION', 'pgsql'),
```

#### Update PostgreSQL Configuration

Locate the `'pgsql'` array in the `'connections'` section and update:

```php
'pgsql' => [
    'driver' => 'pgsql',
    'url' => env('DB_URL'),
    'host' => env('DB_HOST', 'your-project-postgres'),    // ← Change this
    'port' => env('DB_PORT', '5432'),
    'database' => env('DB_DATABASE', 'your-project'),     // ← Change this  
    'username' => env('DB_USERNAME', 'your-project'),     // ← Change this
    'password' => env('DB_PASSWORD', ''),
    'charset' => env('DB_CHARSET', 'utf8'),
    'prefix' => '',
    'prefix_indexes' => true,
    'search_path' => 'public',
    'sslmode' => 'prefer',
],
```

**Important**: Replace `your-project` with your actual project name.

## Complete Example

Here's a complete example of what the `'pgsql'` configuration should look like for a project named `myapp`:

```php
'pgsql' => [
    'driver' => 'pgsql',
    'url' => env('DB_URL'),
    'host' => env('DB_HOST', 'myapp-postgres'),
    'port' => env('DB_PORT', '5432'),
    'database' => env('DB_DATABASE', 'myapp'),
    'username' => env('DB_USERNAME', 'myapp'),
    'password' => env('DB_PASSWORD', ''),
    'charset' => env('DB_CHARSET', 'utf8'),
    'prefix' => '',
    'prefix_indexes' => true,
    'search_path' => 'public',
    'sslmode' => 'prefer',
],
```

## Why These Changes Are Needed

### 1. Container Networking
- **Host**: `your-project-postgres` refers to the PostgreSQL container name
- Docker Compose creates an internal network where services can communicate using their service names

### 2. Database Credentials
- **Database Name**: Must match the `POSTGRES_DB` in the PostgreSQL container
- **Username**: Must match the `POSTGRES_USER` in the PostgreSQL container
- These are automatically set in the Docker Compose configuration

### 3. Default Connection
- Changing from `sqlite` to `pgsql` ensures Laravel uses PostgreSQL by default
- Can still be overridden via the `DB_CONNECTION` environment variable

## Manual vs Automatic Configuration

### Automatic (via setup.sh script)
The setup script automatically makes these changes when you run:
```bash
./setup.sh
```

### Manual Configuration
If you're setting up manually, you need to:

1. Open `config/database.php` in your Laravel project
2. Make the changes listed above
3. Replace `your-project` with your actual project name
4. Save the file

## Verification

After making these changes, you can verify the configuration:

```bash
# Start the containers
docker-compose up -d

# Test database connection
docker-compose exec your-project-php php artisan migrate:status

# If successful, you'll see migration table status
```

## Troubleshooting

### Connection Refused Error
```
SQLSTATE[08006] [7] could not connect to server: Connection refused
```

**Solutions**:
1. Verify PostgreSQL container is running: `docker-compose ps`
2. Check the host name matches your project name + `-postgres`
3. Ensure the database service is healthy: `docker-compose logs your-project-postgres`

### Authentication Failed Error
```
SQLSTATE[08006] [7] FATAL: password authentication failed
```

**Solutions**:
1. Check username and database name match your project name
2. Verify password matches the `DB_PASSWORD` in your `.env` file
3. Ensure PostgreSQL environment variables are correctly set in `compose.yml`

### Database Does Not Exist Error
```
SQLSTATE[08006] [7] FATAL: database "your-project" does not exist
```

**Solutions**:
1. Check the `POSTGRES_DB` environment variable in `compose.yml`
2. Verify the database name in `config/database.php` matches
3. Restart PostgreSQL container: `docker-compose restart your-project-postgres`

## Environment Variables

The Docker setup uses these environment variables (defined in `.env` files):

```env
DB_CONNECTION=pgsql
DB_HOST=your-project-postgres
DB_PORT=5432
DB_DATABASE=your-project
DB_USERNAME=your-project
DB_PASSWORD=laravel
```

These variables are referenced in the Laravel `config/database.php` file via the `env()` helper function.

## Advanced Configuration

### SSL Connection
For production environments, you might want to enable SSL:

```php
'pgsql' => [
    // ... other config
    'sslmode' => 'require',
    'sslcert' => env('DB_SSL_CERT'),
    'sslkey' => env('DB_SSL_KEY'),
    'sslrootcert' => env('DB_SSL_ROOT_CERT'),
],
```

### Connection Pool Settings
For high-traffic applications:

```php
'pgsql' => [
    // ... other config
    'options' => [
        PDO::ATTR_PERSISTENT => true,
        PDO::ATTR_EMULATE_PREPARES => false,
    ],
],
```

### Read/Write Connections
For database replication setups:

```php
'pgsql' => [
    'read' => [
        'host' => [
            'your-project-postgres-read1',
            'your-project-postgres-read2',
        ],
    ],
    'write' => [
        'host' => [
            'your-project-postgres-write',
        ],
    ],
    'driver' => 'pgsql',
    // ... rest of config
],
```

## Migration from SQLite

If you're migrating from SQLite to PostgreSQL:

1. **Export existing data** (if needed):
   ```bash
   php artisan db:show --database=sqlite
   ```

2. **Update configuration** as described above

3. **Run fresh migrations**:
   ```bash
   docker-compose exec your-project-php php artisan migrate:fresh
   ```

4. **Seed data** (if applicable):
   ```bash
   docker-compose exec your-project-php php artisan db:seed
   ```

## Best Practices

1. **Backup your original `config/database.php`** before making changes
2. **Use environment variables** for all database credentials
3. **Never commit database passwords** to version control
4. **Test the connection** after making changes
5. **Keep the setup script updated** if you modify the configuration manually