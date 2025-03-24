# Stage 1: Build Git LFS with updated dependencies
FROM golang:1.23 AS git-lfs-builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    make \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Clone Git LFS
RUN git clone https://github.com/git-lfs/git-lfs.git /go/src/git-lfs

WORKDIR /go/src/git-lfs

# Update Go dependencies
RUN go get -u golang.org/x/crypto && \
    go get -u golang.org/x/net && \
    go mod tidy

# Build Git LFS
RUN make

# Stage 2: Download and setup Java
FROM debian:bookworm-slim AS java-base

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21%2B35/OpenJDK21U-jdk_x64_linux_hotspot_21_35.tar.gz -o /tmp/openjdk-21.tar.gz \
    && mkdir -p ${JAVA_HOME} \
    && tar -xzf /tmp/openjdk-21.tar.gz -C ${JAVA_HOME} --strip-components=1 \
    && rm -f /tmp/openjdk-21.tar.gz

# Stage 3: Download Jenkins
FROM java-base AS jenkins-download

ENV JENKINS_HOME=/var/jenkins_home \
    JENKINS_VERSION=latest \
    JENKINS_UC=https://updates.jenkins.io

# Create directory first, then download Jenkins
RUN mkdir -p /usr/share/jenkins && \
    curl -fsSL https://get.jenkins.io/war-stable/latest/jenkins.war -o /usr/share/jenkins/jenkins.war

# Stage 4: Final stage
FROM debian:bookworm-slim

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    JENKINS_HOME=/var/jenkins_home \
    PATH=/usr/lib/jvm/java-21-openjdk-amd64/bin:$PATH \
    DEBIAN_FRONTEND=noninteractive

# Create necessary directories
RUN mkdir -p ${JAVA_HOME} \
    && mkdir -p ${JENKINS_HOME} \
    && mkdir -p /usr/share/jenkins

# Install required packages including fonts and AWT dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    fontconfig \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    libfreetype6 \
    libfontconfig1 \
    libjpeg62-turbo \
    libpng16-16 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/* \
    && fc-cache -fv

# Copy Java and Jenkins from previous stages
COPY --from=java-base ${JAVA_HOME} ${JAVA_HOME}
COPY --from=jenkins-download /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins.war
COPY --from=git-lfs-builder /go/src/git-lfs/bin/git-lfs /usr/local/bin/

# Setup user and permissions
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins \
    && chown -R jenkins:jenkins ${JENKINS_HOME} /usr/share/jenkins \
    && git lfs install --system \
    && ln -s ${JAVA_HOME}/bin/java /usr/local/bin/java

USER jenkins

EXPOSE 8080 50000

ENTRYPOINT ["/usr/local/bin/java"]
CMD ["-jar", "/usr/share/jenkins/jenkins.war"]