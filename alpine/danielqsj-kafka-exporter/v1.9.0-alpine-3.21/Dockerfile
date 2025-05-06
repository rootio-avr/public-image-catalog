FROM alpine:3.21
MAINTAINER Daniel Qian <qsj.daniel@gmail.com>

ARG TARGETARCH
ARG BIN_DIR=.build/linux-${TARGETARCH}/

# Add ca-certificates for HTTPS/TLS support
RUN apk add --no-cache ca-certificates

# Copy kafka_exporter binary
COPY kafka_exporter /bin/kafka_exporter

# Expose Prometheus scrape port
EXPOSE 9308

# Drop privileges: Alpine comes with user 'nobody' by default
USER nobody

ENTRYPOINT ["/bin/kafka_exporter"]
