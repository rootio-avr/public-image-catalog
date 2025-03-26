# Stage 1: Build dependencies
FROM rootioinc/common-php:8.2.26-apache-bookworm-slim-development AS builder

RUN echo "PHP_INI_DIR is set to: $PHP_INI_DIR"
# Persistent dependencies and build dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libavif15 \
        libfreetype6 \
        libicu72 \
        libjpeg62-turbo \
        libmagickwand-6.q16-6 \
        libpng16-16 \
        libwebp7 \
        libzip4 \
        ghostscript \
        libavif-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libmagickwand-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
    ; \
    rm -rf /var/lib/apt/lists/*
ENV PHP_INI_DIR=/usr/local/etc/php
# Install PHP extensions
RUN set -ex; \
    docker-php-ext-configure gd \
        --with-avif \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-php-config=/usr/local/bin/php-config \
    ; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        zip \
    ; \
    # Imagick installation
    curl -fL -o imagick.tgz 'https://pecl.php.net/get/imagick-3.7.0.tgz'; \
    echo '5a364354109029d224bcbb2e82e15b248be9b641227f45e63425c06531792d3e *imagick.tgz' | sha256sum -c -; \
    tar --extract --directory /tmp --file imagick.tgz imagick-3.7.0; \
    sed -i -e 's!^//#endif$!#endif!' /tmp/imagick-3.7.0/Imagick.stub.php; \
    docker-php-ext-install /tmp/imagick-3.7.0; \
    rm -rf imagick.tgz /tmp/imagick-3.7.0

# Download WordPress
RUN set -eux; \
    version='6.7.1'; \
    sha1='dfb745d4067368bb9a9491f2b6f7e8d52d740fd1'; \
    \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
    echo "$sha1 *wordpress.tar.gz" | sha1sum -c -; \
    \
    tar -xzf wordpress.tar.gz -C /usr/src/; \
    rm wordpress.tar.gz

# Stage 2: Final runtime image
FROM rootioinc/common-php:8.2.26-apache-bookworm-slim-production


# Install runtime dependencies and remove dev packages
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        ghostscript \
        libavif15 \
        libfreetype6 \
        libicu72 \
        libjpeg62-turbo \
        libmagickwand-6.q16-6 \
        libpng16-16 \
        libwebp7 \
        libzip4 \
    ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy PHP extensions from builder
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Enable PHP extensions
# RUN docker-php-ext-enable imagick

# Configure PHP and Apache settings
RUN set -eux; \
    # OPcache settings
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    \
    # Error logging settings
    { \
        echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'log_errors_max_len = 1024'; \
        echo 'ignore_repeated_errors = On'; \
        echo 'ignore_repeated_source = Off'; \
        echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini; \
    \
    # Apache modules and configuration
    a2enmod rewrite expires; \
    a2enmod remoteip; \
    { \
        echo 'RemoteIPHeader X-Forwarded-For'; \
        echo 'RemoteIPInternalProxy 10.0.0.0/8'; \
        echo 'RemoteIPInternalProxy 172.16.0.0/12'; \
        echo 'RemoteIPInternalProxy 192.168.0.0/16'; \
        echo 'RemoteIPInternalProxy 169.254.0.0/16'; \
        echo 'RemoteIPInternalProxy 127.0.0.0/8'; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip; \
    find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +

# Copy WordPress files
COPY --from=builder /usr/src/wordpress /usr/src/wordpress
RUN set -eux; \
    { \
    echo '# BEGIN WordPress'; \
    echo ''; \
    echo 'RewriteEngine On'; \
    echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
    echo 'RewriteBase /'; \
    echo 'RewriteRule ^index\.php$ - [L]'; \
    echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
    echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
    echo 'RewriteRule . /index.php [L]'; \
    echo ''; \
    echo '# END WordPress'; \
    } > /usr/src/wordpress/.htaccess; \
    \
    chown -R www-data:www-data /usr/src/wordpress; \
# Prepare WordPress content directory
    mkdir wp-content; \
    for dir in /usr/src/wordpress/wp-content/*/ cache; do \
        dir="$(basename "${dir%/}")"; \
        mkdir "wp-content/$dir"; \
    done; \
    chown -R www-data:www-data wp-content; \
    chmod -R 1777 wp-content

# Add WordPress configuration and entrypoint
COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]