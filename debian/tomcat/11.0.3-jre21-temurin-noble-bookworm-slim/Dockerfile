# Use Eclipse Temurin JRE 21 base image with Debian Bookworm slim
FROM rootioinc/common-eclipse-temurin:21-jre-bookworm-slim

# Set environment variables
ENV TOMCAT_VERSION=11.0.3
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

RUN mkdir -p "$CATALINA_HOME"

# Install curl and dependencies for Tomcat Native (APR)
RUN apt-get update && apt-get install -y \
    curl \
    libapr1 \
    libtcnative-1 \
    && rm -rf /var/lib/apt/lists/*

# Download and extract the correct Tomcat 11.0.3 binary package
RUN curl -fsSL -o /tmp/tomcat.tar.gz "https://archive.apache.org/dist/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" && \
    tar xzf /tmp/tomcat.tar.gz -C "$CATALINA_HOME" --strip-components=1 && \
    rm /tmp/tomcat.tar.gz

WORKDIR $CATALINA_HOME

# Security: Create and use a non-root user for Tomcat
RUN groupadd -r tomcat && useradd -r -g tomcat tomcat && \
    chown -R tomcat:tomcat $CATALINA_HOME
USER tomcat

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat when the container runs
CMD ["catalina.sh", "run"]
