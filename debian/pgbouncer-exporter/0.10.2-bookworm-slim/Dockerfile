ARG ARCH="amd64"
ARG OS="linux"
FROM  rootioinc/common-prometheus:3.0.1-bookworm-slim
LABEL maintainer="The Prometheus Authors <prometheus-developers@googlegroups.com>"

ARG ARCH="amd64"
ARG OS="linux"
COPY pgbouncer_exporter /bin/pgbouncer_exporter
COPY LICENSE                                /LICENSE

USER       nobody
ENTRYPOINT ["/bin/pgbouncer_exporter"]
EXPOSE     9127
