ARG ARCH="amd64"
ARG OS="linux"
FROM rootioinc/common-prometheus:3.0.1-bookworm-slim
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"

ARG ARCH="amd64"
ARG OS="linux"
COPY node_exporter /bin/node_exporter

EXPOSE      9100
USER        nobody
ENTRYPOINT  [ "/bin/node_exporter" ]