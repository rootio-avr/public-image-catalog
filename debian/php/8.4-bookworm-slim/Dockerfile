# Build stage
FROM debian:bookworm-slim AS build

# Dependencies required for building PHP
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        autoconf \
        dpkg-dev \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkg-config \
        re2c \
        ca-certificates \
        curl \
        xz-utils \
        gnupg \
        libargon2-dev \
        libcurl4-openssl-dev \
        libonig-dev \
        libreadline-dev \
        libsodium-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        zlib1g-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

# Environment variables for PHP build
ENV PHPIZE_DEPS="autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c"
ENV PHP_INI_DIR=/usr/local/etc/php
ENV PHP_VERSION=8.4.6
ENV PHP_URL="https://www.php.net/distributions/php-8.4.6.tar.xz"
ENV PHP_SHA256="089b08a5efef02313483325f3bacd8c4fe311cf1e1e56749d5cc7d059e225631"
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

RUN set -eux; \
    mkdir -p /usr/src; \
    mkdir -p "$PHP_INI_DIR"; \
    mkdir -p "$PHP_INI_DIR/conf.d"; \
    curl -fsSL -o /usr/src/php.tar.xz "$PHP_URL"; \
    echo "$PHP_SHA256 /usr/src/php.tar.xz" | sha256sum -c -; \
    mkdir -p /usr/src/php; \
    tar -xf /usr/src/php.tar.xz -C /usr/src/php --strip-components=1; \
    rm /usr/src/php.tar.xz; \
    cd /usr/src/php; \
    ./configure \
        --prefix=/usr/local \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-mhash \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium=shared \
        --with-pdo-sqlite=/usr \
        --with-sqlite3=/usr \
        --with-curl \
        --with-iconv \
        --with-openssl \
        --with-readline \
        --with-zlib \
        --enable-phpdbg \
        --enable-phpdbg-readline \
        --with-pear \
        --enable-embed \
        --with-libdir="lib/$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
    ; \
    make -j "$(nproc)"; \
    make install; \
    make clean; \
    cp php.ini-* "$PHP_INI_DIR/"; \
    pecl update-channels; \
    rm -rf /tmp/pear ~/.pearrc; \
    rm -rf /usr/src/php

# Final stage
FROM debian:bookworm-slim

# Copy PHP from the build stage
COPY --from=build /usr/local /usr/local
COPY --from=build /usr/local/etc/php /usr/local/etc/php

# Install runtime dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libargon2-1 \
        libcurl4 \
        libonig5 \
        libreadline8 \
        libsodium23 \
        libsqlite3-0 \
        libssl3 \
        libxml2 \
        zlib1g \
    ; \
    rm -rf /var/lib/apt/lists/*

# Create required directories and permissions
RUN set -eux; \
    mkdir -p /var/www/html; \
    chown www-data:www-data /var/www/html; \
    chmod 1777 /var/www/html

# Enable sodium extension manually
RUN echo "extension=sodium.so" > /usr/local/etc/php/conf.d/sodium.ini

# Set up entrypoint and default command
COPY docker-php-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]
