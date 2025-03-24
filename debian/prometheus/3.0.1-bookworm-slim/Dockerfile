ARG ARCH="amd64"
ARG OS="linux"

# Use debian:bookworm-slim as the base image
FROM debian:bookworm-slim

LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"
LABEL org.opencontainers.image.source="https://github.com/prometheus/prometheus"

# Install necessary dependencies (curl, ca-certificates, etc.)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Ensure that 'nobody' user and group exist, and if not, create them as system accounts
RUN getent group nobody || addgroup --system nobody && \
    getent passwd nobody || adduser --system --no-create-home --ingroup nobody nobody

# Copy the Prometheus and Promtool binaries
COPY prometheus /bin/prometheus
COPY promtool /bin/promtool

# Copy other necessary files
COPY documentation/examples/prometheus.yml /etc/prometheus/prometheus.yml
COPY LICENSE /LICENSE
COPY NOTICE /NOTICE
COPY npm_licenses.tar.bz2 /npm_licenses.tar.bz2

# Set the working directory
WORKDIR /prometheus

# Change ownership to the 'nobody' user and group
RUN chown -R nobody:nobody /etc/prometheus /prometheus

# Switch to a non-root user for security
USER nobody

# Expose the default Prometheus port
EXPOSE 9090

# Define the Prometheus data directory
VOLUME [ "/prometheus" ]

# Define the default entrypoint and command
ENTRYPOINT [ "/bin/prometheus" ]
CMD [ "--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus" ]
