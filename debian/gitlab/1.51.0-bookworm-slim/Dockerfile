# syntax=docker/dockerfile:1

FROM debian:bookworm-slim

# Install required dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    nano \
    openssh-client \
    curl \
    ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install the latest glab release from GitLab
RUN curl -fsSL https://gitlab.com/gitlab-org/cli/-/releases/v1.51.0/downloads/glab_1.51.0_linux_amd64.deb -o /tmp/glab.deb && \
    apt install -y /tmp/glab.deb && \
    rm /tmp/glab.deb

# Set the default command to glab
CMD ["glab"]
