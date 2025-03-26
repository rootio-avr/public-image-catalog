# Step 1: Use the slim version of Debian Bookworm as the base image for the build environment
FROM debian:bookworm-slim as builder

# Set environment variables for non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.22.7
RUN curl -fsSL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz -o /tmp/go1.22.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xvzf /tmp/go1.22.4.linux-amd64.tar.gz && \
    rm /tmp/go1.22.4.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

RUN git clone https://github.com/kbudde/rabbitmq_exporter.git /go/src/github.com/kbudde/rabbitmq_exporter
WORKDIR /go/src/github.com/kbudde/rabbitmq_exporter

RUN git checkout v1.0.0

RUN go mod tidy && \
    go build -o rabbitmq_exporter .

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/src/github.com/kbudde/rabbitmq_exporter/rabbitmq_exporter /usr/local/bin/

EXPOSE 9419

CMD ["rabbitmq_exporter"]
