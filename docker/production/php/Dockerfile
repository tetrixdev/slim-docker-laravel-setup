# Build stage - includes Node.js for asset compilation
FROM laravel-php-base AS builder

# Copy Laravel application
COPY www/ /var/www/

# Install Composer dependencies (production)
RUN composer install --no-dev --optimize-autoloader --no-interaction --verbose

# Install npm dependencies and build assets
RUN npm ci --only=production \
    && npm run build \
    && rm -rf node_modules

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Production stage - clean runtime
FROM laravel-php-base AS runtime

# Copy built application from builder stage
COPY --from=builder --chown=www-data:www-data /var/www /var/www

# Copy PHP configuration
COPY docker/shared/php/local.ini /usr/local/etc/php/conf.d/local.ini

# Copy production entrypoint
COPY docker/production/php/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to www-data user for security
USER www-data

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Use production entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]