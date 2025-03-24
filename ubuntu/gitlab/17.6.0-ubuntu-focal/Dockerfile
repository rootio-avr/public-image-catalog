# Build Stage
FROM ubuntu:20.04 AS build

# Install required tools
RUN apt-get update && apt-get install -y curl wget git build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Go 1.21 or later
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz -O go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# Download GitLab Runner source
WORKDIR /usr/local/src
RUN wget https://gitlab.com/gitlab-org/gitlab-runner/-/archive/v17.6.0/gitlab-runner-v17.6.0.tar.gz \
    && tar -xzf gitlab-runner-v17.6.0.tar.gz \
    && mv gitlab-runner-v17.6.0 gitlab-runner \
    && rm gitlab-runner-v17.6.0.tar.gz

# Update go.mod with specified dependencies
WORKDIR /usr/local/src/gitlab-runner
RUN sed -i '/require (/a \
    golang.org/x/net v0.33.0\n    golang.org/x/crypto v0.31.0' go.mod

# Build GitLab Runner binary
RUN go mod tidy \
    && go build -o /usr/local/bin/gitlab-runner .

# Final Stage
FROM ubuntu:20.04

# Copy GitLab Runner binary from build stage
COPY --from=build /usr/local/bin/gitlab-runner /usr/local/bin/gitlab-runner

# Verify installation
RUN gitlab-runner --version

# Create necessary directories
RUN mkdir -p /etc/gitlab-runner /home/gitlab-runner

# Copy the configuration file
COPY config.toml /etc/gitlab-runner/config.toml

# Set up volumes
VOLUME ["/etc/gitlab-runner", "/home/gitlab-runner"]

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/gitlab-runner"]

# Default command
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]