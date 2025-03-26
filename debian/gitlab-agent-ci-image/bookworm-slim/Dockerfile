# Stage 1: Builder
FROM debian:bookworm-slim AS builder

ARG TARGETARCH
ARG GO_VERSION=1.23.1
ARG BAZELISK_VERSION=v1.25.0
ARG BUILD_DIR=/tmp/build
ARG GO_URL="https://dl.google.com/go/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz"
ARG COSIGN_VERSION=2.4.1
ARG CRANE_VERSION=0.20.2
ARG CRANE_SRC_URL="https://github.com/google/go-containerregistry/archive/refs/tags/v${CRANE_VERSION}.tar.gz"

# Install required packages
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl python3 clang git make patch gnupg lsb-release xz-utils tar gzip \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$TARGETARCH signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io \
  && rm -rf "/var/lib/apt/lists/*" \
  && ln -sf /usr/bin/python3 /usr/local/bin/python

# Install Go
RUN mkdir ${BUILD_DIR} \
  && curl --retry 6 -so golang.tar.gz ${GO_URL} \
  && tar -xf golang.tar.gz \
  && mv go /usr/local/go \
  && rm golang.tar.gz \
  && ln -sf /usr/local/go/bin/go /usr/local/bin/go \
  && rm -rf ${BUILD_DIR}

ENV PATH="/usr/local/go/bin:$PATH"
ENV CC="/usr/bin/clang"

# Download and build Crane from source
WORKDIR /tmp/crane
RUN curl -fsSL ${CRANE_SRC_URL} -o crane-src.tar.gz \
  && tar -xzf crane-src.tar.gz --strip-components=1 \
  && rm crane-src.tar.gz \
  && sed -i 's/^go [0-9.]*$/go 1.23.1/' go.mod \
  && go mod tidy \
  && go build -ldflags "-X main.version=v${CRANE_VERSION}" -o /usr/local/bin/crane ./cmd/crane

# Install and update Cosign
WORKDIR /tmp/cosign
RUN curl -fsSL https://github.com/sigstore/cosign/archive/refs/tags/v${COSIGN_VERSION}.tar.gz -o cosign-src.tar.gz \
  && tar -xzf cosign-src.tar.gz --strip-components=1 \
  && rm cosign-src.tar.gz \
  && go mod edit -require=golang.org/x/crypto@v0.31.0 \
  && go mod edit -require=golang.org/x/net@v0.33.0 \
  && go mod tidy \
  && go build -ldflags "-s -w -X sigs.k8s.io/release-utils/version.gitVersion=v${COSIGN_VERSION}" -o /usr/local/bin/cosign ./cmd/cosign


# Install Bazelisk
RUN go install github.com/bazelbuild/bazelisk@${BAZELISK_VERSION} \
  && rm -rf /root/go/pkg \
  && mv /root/go/bin/bazelisk /usr/local/bin/bazel

# Stage 2: Final Image
FROM debian:bookworm-slim AS final

ARG TARGETARCH

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl python3 git xz-utils \
  && ln -sf /usr/bin/python3 /usr/local/bin/python \
  && rm -rf "/var/lib/apt/lists/*"

COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /usr/local/bin/bazel /usr/local/bin/bazel
COPY --from=builder /usr/local/bin/crane /usr/local/bin/crane
COPY --from=builder /usr/bin/clang /usr/bin/clang
COPY --from=builder /usr/local/bin/cosign /usr/local/bin/cosign

RUN useradd --create-home --shell /bin/bash ci
USER ci
WORKDIR /home/ci
