# Stage 1: Use the original image to copy prebuilt app
FROM docker.elastic.co/elastic-maps-service/elastic-maps-server-ubi:8.17.0 as original

# Stage 2: Debian-based minimal runtime image
FROM debian:bookworm-slim

# Install runtime dependencies (no build tools or dev libs)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    fontconfig \
    libfreetype6 \
    procps \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js from official binary release (no APT dev deps)
ENV NODE_VERSION=18.19.1
RUN curl -fsSL https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz \
    | tar -xJ -C /usr/local --strip-components=1 \
 && ln -s /usr/local/bin/node /usr/bin/node \
 && ln -s /usr/local/bin/npm /usr/bin/npm \
 && node -v && npm -v

# Create non-root user matching original image
RUN useradd -m -u 1000 node

# Set environment variables
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    EMS_DIR=/usr/src/app \
    EMS_DATA_DIR=/usr/src/app/data \
    NODE_ENV=production

# Create necessary directories with correct permissions
RUN mkdir -p /usr/src/app/data && \
    mkdir -p /var/log/elastic-maps-server && \
    chown -R node:node /usr/src/app && \
    chown -R node:node /var/log/elastic-maps-server

# Copy prebuilt app from original image
COPY --from=original --chown=node:node /usr/src/app /usr/src/app

# Optional: re-install only production dependencies (skip if node_modules is already present)
WORKDIR /usr/src/app
RUN [ -f package.json ] && npm ci --omit=dev || true

# Switch to non-root user
USER node
WORKDIR /usr/src/app/server/

# Expose application port
EXPOSE 8080/tcp

# Healthcheck as in original image
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s \
  CMD node --no-warnings "${EMS_DIR}/server/app/healthcheck.js"

# Start the server
CMD ["/bin/sh", "-c", "node \"app/index.js\""]
