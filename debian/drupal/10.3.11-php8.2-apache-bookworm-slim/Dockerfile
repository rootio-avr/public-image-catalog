# Build stage for PHP dependencies
FROM rootioinc/common-php:8.2.26-apache-bookworm-slim-development AS build

# Install build dependencies and PHP extensions
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
        libwebp-dev \
        libzip-dev \
        unzip; \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg=/usr \
        --with-webp; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        zip; \
    apt-get purge -y --auto-remove; \
    rm -rf /var/lib/apt/lists/*

# Configure PHP Opcache
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini
# Remove sodium configuration if it exists
RUN set -eux; \
    if [ -f /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini ]; then \
        rm /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini; \
    fi
    
# Copy Composer from official image for PHP dependencies
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/

WORKDIR /opt/drupal

# Set up Drupal in the build stage
ENV DRUPAL_VERSION 10.3.11
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN set -eux; \
    export COMPOSER_HOME="$(mktemp -d)"; \
    composer create-project --no-interaction "drupal/recommended-project:$DRUPAL_VERSION" ./; \
    composer check-platform-reqs; \
    chown -R www-data:www-data web/sites web/modules web/themes; \
    # Delete Composer cache to reduce size
    rm -rf "$COMPOSER_HOME"

# Final stage: Minimal runtime image
FROM rootioinc/common-php:8.2.26-apache-bookworm-slim-production

# Install runtime dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libpq5 \
        libwebp7 \
        libzip4; \
    rm -rf /var/lib/apt/lists/*

# Copy PHP extensions and configuration from the build stage
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy Drupal application from the build stage
COPY --from=build /opt/drupal /opt/drupal

# Copy Composer binary
COPY --from=build /usr/local/bin/composer /usr/local/bin/composer

# Set up Apache and symlink Drupal web directory
RUN set -eux; \
    if command -v a2enmod; then \
        a2enmod expires rewrite; \
    fi; \
    rmdir /var/www/html; \
    ln -s /opt/drupal/web /var/www/html

# Add Drupal vendor binaries to PATH
ENV PATH=${PATH}:/opt/drupal/vendor/bin

WORKDIR /var/www/html

# Expose default HTTP port
EXPOSE 80

# Default command
CMD ["apache2-foreground"]

# vim:set ft=dockerfile:
