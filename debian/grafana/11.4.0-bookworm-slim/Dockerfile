# Build stage
FROM golang:1.23.5-bookworm as builder

# Accept a commit SHA as a build argument
ARG COMMIT_SHA=""

# Set the commit SHA as an environment variable
ENV COMMIT_SHA=${COMMIT_SHA}

# Install Node.js and Yarn (required for Grafana frontend build)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Download and extract specific version of Grafana
WORKDIR /grafana
RUN curl -fsSL https://github.com/grafana/grafana/archive/refs/tags/v11.4.0.tar.gz | tar xz --strip-components=1

# Update the version in package.json
RUN sed -i 's/"version": ".*"/"version": "11.4.0"/' package.json

# Update Go dependencies
RUN go get -u golang.org/x/crypto && \
    go get -u golang.org/x/net && \
    go mod tidy


# Build Grafana
RUN make deps-go && \
    make build-go && \
    yarn install && \
    yarn build

# Final stage
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    bash \
    curl \
    tzdata \
    musl \
    libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Create Grafana user and group
RUN groupadd -r grafana && \
    useradd -r -g grafana -m -d /usr/share/grafana grafana

# Set environment variables
ENV GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning" \
    GF_SERVER_HTTP_ADDR=0.0.0.0

# Create required directories
RUN mkdir -p $GF_PATHS_HOME $GF_PATHS_DATA $GF_PATHS_LOGS $GF_PATHS_PLUGINS $GF_PATHS_PROVISIONING \
    /usr/share/grafana/plugins-bundled \
    /etc/grafana/provisioning/dashboards \
    /etc/grafana/provisioning/datasources \
    /etc/grafana/provisioning/plugins \
    /etc/grafana/provisioning/alerting

# Copy built Grafana from builder stage
COPY --from=builder /grafana/bin/linux-amd64/grafana-server /usr/local/bin/grafana-server
COPY --from=builder /grafana/bin/linux-amd64/grafana /usr/local/bin/grafana
COPY --from=builder /grafana/public /usr/share/grafana/public
COPY --from=builder /grafana/conf /usr/share/grafana/conf

# Use the default configuration as grafana.ini
RUN cp /usr/share/grafana/conf/defaults.ini /etc/grafana/grafana.ini

# Set permissions
RUN chown -R grafana:grafana $GF_PATHS_HOME $GF_PATHS_DATA $GF_PATHS_LOGS $GF_PATHS_PLUGINS $GF_PATHS_PROVISIONING /etc/grafana

# Optionally, copy default provisioning files (if you have any)
# COPY provisioning/dashboards /etc/grafana/provisioning/dashboards/
# COPY provisioning/datasources /etc/grafana/provisioning/datasources/
# COPY provisioning/plugins /etc/grafana/provisioning/plugins/
# COPY provisioning/alerting /etc/grafana/provisioning/alerting/

WORKDIR $GF_PATHS_HOME

EXPOSE 3000

USER grafana

# Start Grafana server with proper homepath and config
CMD ["grafana", "server", "--homepath=/usr/share/grafana", "--config=/etc/grafana/grafana.ini"]
