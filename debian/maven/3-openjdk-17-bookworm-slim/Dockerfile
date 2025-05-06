# Start with the Debian bookworm slim base image
FROM debian:bookworm-slim

# Set up Java environment variables
ENV JAVA_HOME=/usr/local/openjdk-17 \
    PATH=/usr/local/openjdk-17/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LANG=C.UTF-8 \
    JAVA_VERSION=17.0.2

# Install dependencies required for Java
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg \
        dirmngr \
        fontconfig \
        libfreetype6 \
        p11-kit \
        tzdata \
    ; \
    rm -rf /var/lib/apt/lists/*

# Install OpenJDK 17
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
       amd64 | x86_64) \
         downloadUrl="https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz"; \
         downloadSha256='0022753d0cceecacdd3a795dd4cea2bd7ffdf9dc06e22ffd1be98411742fbb44'; \
         ;; \
       arm64) \
         downloadUrl='https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz'; \
         downloadSha256='13bfd976acf8803f862e82c7113fb0e9311ca5458b1decaef8a09ffd91119fa4'; \
         ;; \
       *) \
         echo "Unsupported architecture: $arch"; \
         exit 1; \
         ;; \
    esac; \
    wget --progress=dot:giga -O openjdk.tgz "$downloadUrl"; \
    echo "$downloadSha256 *openjdk.tgz" | sha256sum --strict --check -; \
    mkdir -p "$JAVA_HOME"; \
    tar --extract \
        --file openjdk.tgz \
        --directory "$JAVA_HOME" \
        --strip-components 1 \
        --no-same-owner \
    ; \
    rm openjdk.tgz*; \
    # Basic check to validate installation
    "$JAVA_HOME/bin/java" -version

# Set Maven environment variables and ARGs
ARG MAVEN_VERSION=3.8.5
ARG USER_HOME_DIR="/root"
ARG BASE_URL=https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries
# Add SHA for verification just like in the original image
ARG SHA=89ab8ece99292476447ef6a6800d9842bbb60787b9b8a45c103aa61d2f205a971d8c3ddfb8b03e514455b4173602bd015e82958c0b3ddc1728a57126f773c743

ENV MAVEN_HOME=/usr/share/maven \
    MAVEN_CONFIG=/root/.m2

# Install Maven with all required dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        procps \
    && \
    mkdir -p /usr/share/maven /usr/share/maven/ref && \
    curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - && \
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 && \
    rm -f /tmp/apache-maven.tar.gz && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the files from the original image
COPY settings-docker.xml /usr/share/maven/ref/
COPY mvn-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mvn-entrypoint.sh

# Set ENTRYPOINT and default CMD
ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
CMD ["mvn"] 