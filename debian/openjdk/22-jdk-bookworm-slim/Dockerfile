#Ref: https://github.com/ibmruntimes/semeru-containers/blob/0d581de9acf0fefbd9f7c5d7844fa0838d49a27d/22/jdk/ubuntu/jammy/Dockerfile.open.releases.full

FROM debian:bookworm-slim

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

RUN apt-get update \
    && apt-get install -y --no-install-recommends tzdata curl ca-certificates fontconfig locales \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_VERSION jdk-22.0.2+9_openj9-0.46.1

RUN set -eux; \
    ARCH="$(dpkg --print-architecture)"; \
    case "${ARCH}" in \
       aarch64|arm64) \
         ESUM='b4da4670045724892e379701e1ec1f4b93800cc8560258685c826579ffb101bf'; \
         BINARY_URL='https://github.com/ibmruntimes/semeru22-binaries/releases/download/jdk-22.0.2%2B9_openj9-0.46.1/ibm-semeru-open-jdk_aarch64_linux_22.0.2_9_openj9-0.46.1.tar.gz'; \
         ;; \
       amd64|x86_64) \
         ESUM='7fa2780c81063aa2756c4d49940a368b7d2d41d0538809b6512e762a554052ac'; \
         BINARY_URL='https://github.com/ibmruntimes/semeru22-binaries/releases/download/jdk-22.0.2%2B9_openj9-0.46.1/ibm-semeru-open-jdk_x64_linux_22.0.2_9_openj9-0.46.1.tar.gz'; \
         ;; \
       ppc64el|ppc64le) \
         ESUM='0212b31251e35f18d2d973f028e27c26e2c57888e3f2df56a1c851a5bc54aedf'; \
         BINARY_URL='https://github.com/ibmruntimes/semeru22-binaries/releases/download/jdk-22.0.2%2B9_openj9-0.46.1/ibm-semeru-open-jdk_ppc64le_linux_22.0.2_9_openj9-0.46.1.tar.gz'; \
         ;; \
       s390x) \
         ESUM='e2fb0640f828d76820c8b36821abfe9235bdae3efedb3a9ec98021b8dcefce60'; \
         BINARY_URL='https://github.com/ibmruntimes/semeru22-binaries/releases/download/jdk-22.0.2%2B9_openj9-0.46.1/ibm-semeru-open-jdk_s390x_linux_22.0.2_9_openj9-0.46.1.tar.gz'; \
         ;;\
       *) \
         echo "Unsupported arch: ${ARCH}"; \
         exit 1; \
         ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH="/opt/java/openjdk/bin:$PATH"
ENV JAVA_TOOL_OPTIONS="-XX:+IgnoreUnrecognizedVMOptions -XX:+PortableSharedCache -XX:+IdleTuningGcOnIdle -Xshareclasses:name=openj9_system_scc,cacheDir=/opt/java/.scc,readonly,nonFatal"
