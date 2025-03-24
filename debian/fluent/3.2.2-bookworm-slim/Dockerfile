# syntax=docker/dockerfile:1
# Set the release version
ARG RELEASE_VERSION=3.2.2

FROM multiarch/qemu-user-static:x86_64-arm AS qemu-arm32
FROM multiarch/qemu-user-static:x86_64-aarch64 AS qemu-arm64

FROM debian:bookworm-slim AS builder-base

COPY --from=qemu-arm32 /usr/bin/qemu-arm-static /usr/bin/
COPY --from=qemu-arm64 /usr/bin/qemu-aarch64-static /usr/bin/

ARG RELEASE_VERSION
ARG FLB_NIGHTLY_BUILD
ENV FLB_NIGHTLY_BUILD=$FLB_NIGHTLY_BUILD

ARG FLB_CHUNK_TRACE=On
ENV FLB_CHUNK_TRACE=${FLB_CHUNK_TRACE}

RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN echo "deb http://deb.debian.org/debian bookworm-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    cmake \
    git \
    make \
    tar \
    libssl-dev \
    libsasl2-dev \
    pkg-config \
    libsystemd-dev/bookworm-backports \
    zlib1g-dev \
    libpq-dev \
    postgresql-server-dev-all \
    flex \
    bison \
    libyaml-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Work in source directory
WORKDIR /src/fluent-bit/

# Fetch source code using the release version
RUN curl -L "https://github.com/fluent/fluent-bit/archive/refs/tags/v${RELEASE_VERSION}.tar.gz" -o fluent-bit.tar.gz && \
    tar -xvf fluent-bit.tar.gz --strip-components=1 && \
    rm fluent-bit.tar.gz


# We split the builder setup out so people can target it or use as a base image without doing a full build.
FROM builder-base AS builder
WORKDIR /src/fluent-bit/build/
RUN cmake -DFLB_RELEASE=On \
    -DFLB_JEMALLOC=On \
    -DFLB_TLS=On \
    -DFLB_SHARED_LIB=Off \
    -DFLB_EXAMPLES=Off \
    -DFLB_HTTP_SERVER=On \
    -DFLB_IN_EXEC=Off \
    -DFLB_IN_SYSTEMD=On \
    -DFLB_OUT_KAFKA=On \
    -DFLB_OUT_PGSQL=On \
    -DFLB_NIGHTLY_BUILD="$FLB_NIGHTLY_BUILD" \
    -DFLB_LOG_NO_CONTROL_CHARS=On \
    -DFLB_CHUNK_TRACE="$FLB_CHUNK_TRACE" \
    ..

RUN make -j "$(getconf _NPROCESSORS_ONLN)"
RUN install bin/fluent-bit /fluent-bit/bin/


# Copy configuration files from builder-base stage
COPY --from=builder-base /src/fluent-bit/conf/fluent-bit.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers_ambassador.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers_java.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers_extra.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers_openstack.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/parsers_cinder.conf /fluent-bit/etc/
COPY --from=builder-base /src/fluent-bit/conf/plugins.conf /fluent-bit/etc/


# Generate schema and include as part of the container image
RUN /fluent-bit/bin/fluent-bit -J > /fluent-bit/etc/schema.json

# Production stage
FROM debian:bookworm-slim AS production
ARG RELEASE_VERSION
ENV FLUENT_BIT_VERSION=${RELEASE_VERSION}

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl3 \
    libsasl2-2 \
    libpq5 \
    libsystemd0 \
    zlib1g \
    ca-certificates \
    libatomic1 \
    libgcrypt20 \
    libzstd1 \
    liblz4-1 \
    libgssapi-krb5-2 \
    libldap-2.5 \
    libgpg-error0 \
    libkrb5-3 \
    libk5crypto3 \
    libcom-err2 \
    libkrb5support0 \
    libgnutls30 \
    libkeyutils1 \
    libp11-kit0 \
    libidn2-0 \
    libunistring2 \
    libtasn1-6 \
    libnettle8 \
    libhogweed6 \
    libgmp10 \
    libffi8 \
    liblzma5 \
    libyaml-0-2 \
    libcap2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Labels
LABEL description="Fluent Bit container image" \
    vendor="Fluent Organization" \
    version="${RELEASE_VERSION}" \
    author="Eduardo Silva <eduardo.silva@chronosphere.io>" \
    org.opencontainers.image.description="Fluent Bit container image" \
    org.opencontainers.image.title="Fluent Bit" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.vendor="Fluent Organization" \
    org.opencontainers.image.version="${RELEASE_VERSION}" \
    org.opencontainers.image.source="https://github.com/fluent/fluent-bit" \
    org.opencontainers.image.documentation="https://docs.fluentbit.io/" \
    org.opencontainers.image.authors="Eduardo Silva <eduardo.silva@chronosphere.io>"

# Copy certificates
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

# Copy Fluent Bit binaries and configurations
COPY --from=builder /fluent-bit /fluent-bit

# Expose metrics port
EXPOSE 2020

# Entry point
ENTRYPOINT [ "/fluent-bit/bin/fluent-bit" ]
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
