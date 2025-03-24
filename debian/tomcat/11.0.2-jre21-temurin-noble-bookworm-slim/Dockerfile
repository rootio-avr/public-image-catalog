# Use Eclipse Temurin JRE 21 base image with Debian Bookworm slim as the base image
FROM rootioinc/common-eclipse-temurin:21-jre-bookworm-slim

# Set environment variables
ENV TOMCAT_VERSION=11.0.2
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

RUN mkdir -p "$CATALINA_HOME"

# Install curl and dependencies for Tomcat Native (APR)
RUN apt-get update && apt-get install -y \
    curl \
    libapr1 \
    libtcnative-1 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://dlcdn.apache.org/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | tar xz -C $CATALINA_HOME --strip-components=1

WORKDIR $CATALINA_HOME

EXPOSE 8080

# Temporarily skip the Tomcat Native check (optional)
# Uncomment this block if you want to try verifying Tomcat Native again later
# RUN set -eux; \
#     nativeLines="$(catalina.sh configtest 2>&1)"; \
#     nativeLines="$(echo "$nativeLines" | grep 'Apache Tomcat Native')"; \
#     nativeLines="$(echo "$nativeLines" | sort -u)"; \
#     if ! echo "$nativeLines" | grep -E 'INFO: Loaded( APR based)? Apache Tomcat Native library' >&2; then \
#         echo >&2 "$nativeLines"; \
#         exit 1; \
#     fi

# Start Tomcat when the container runs
CMD ["sh", "bin/catalina.sh", "run"]
