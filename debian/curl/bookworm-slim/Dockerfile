# Dockerfile for curl container
FROM debian:bookworm-slim

# Metadata
LABEL description="A minimal Docker image with curl based on Debian Bookworm Slim."

# Update and install curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure certificates are up to date
RUN update-ca-certificates

# Set the default command to curl
ENTRYPOINT ["curl"]
CMD ["--help"]
