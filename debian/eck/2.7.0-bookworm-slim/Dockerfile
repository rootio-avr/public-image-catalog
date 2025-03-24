# Build the operator binary
FROM --platform=$TARGETPLATFORM docker.io/library/golang:1.23.1 as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG GO_LDFLAGS
ARG GO_TAGS
WORKDIR /go/src/github.com/elastic/cloud-on-k8s

# Cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
COPY ["go.mod", "go.sum", "./"]
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod go mod download

# Copy the go source
COPY pkg/    pkg/
COPY cmd/    cmd/

# Build
RUN --mount=type=cache,mode=0755,target=/go/pkg/mod CGO_ENABLED=0 GOOS=linux \
      go build \
      -mod readonly \
      -ldflags "$GO_LDFLAGS" -tags="$GO_TAGS" -a \
      -o elastic-operator github.com/elastic/cloud-on-k8s/v2/cmd

# Rebase to debian:bookworm-slim for a lighter image
FROM debian:bookworm-slim

ARG VERSION

# Install necessary dependencies (e.g., ca-certificates for SSL, etc.)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libc6 \
    libgcc1 \
    && rm -rf /var/lib/apt/lists/*

# Add common ECK labels and OCI annotations to the image
LABEL io.k8s.description="Elastic Cloud on Kubernetes automates the deployment, provisioning, management, and orchestration of Elasticsearch, Kibana, APM Server, Beats, and Enterprise Search on Kubernetes" \
      io.k8s.display-name="Elastic Cloud on Kubernetes" \
      org.opencontainers.image.authors="eck@elastic.co" \
      org.opencontainers.image.base.name="debian:bookworm-slim" \
      org.opencontainers.image.description="Elastic Cloud on Kubernetes automates the deployment, provisioning, management, and orchestration of Elasticsearch, Kibana, APM Server, Beats, and Enterprise Search on Kubernetes" \
      org.opencontainers.image.documentation="https://www.elastic.co/guide/en/cloud-on-k8s/" \
      org.opencontainers.image.licenses="Elastic-License-2.0" \
      org.opencontainers.image.source="https://github.com/elastic/cloud-on-k8s/" \
      org.opencontainers.image.title="Elastic Cloud on Kubernetes" \
      org.opencontainers.image.vendor="Elastic" \
      org.opencontainers.image.version="$VERSION" \
      org.opencontainers.image.url="https://github.com/elastic/cloud-on-k8s/"

# Copy the operator binary into the image
COPY --from=builder /go/src/github.com/elastic/cloud-on-k8s/elastic-operator /elastic-operator

# Copy NOTICE.txt and LICENSE.txt into the image
COPY *.txt /licenses/

# Define the entry point and command for the container
ENTRYPOINT ["/elastic-operator"]
CMD ["manager"]
