###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

FROM rootioinc/common-eclipse-temurin:21-jre-bookworm-slim AS build-jsa

USER root

# Get kafka from https://archive.apache.org/dist/kafka and pass the URL through build arguments
ARG kafka_url

COPY jsa_launch /etc/kafka/docker/jsa_launch

RUN set -eux ; \
    apt-get update ; \
    apt-get upgrade -y ; \
    apt-get install -y wget gpg gnupg procps bash ca-certificates ; \
    mkdir -p /opt/kafka; \
    wget -nv -O kafka.tgz "$kafka_url"; \
    wget -nv -O kafka.tgz.asc "$kafka_url.asc"; \
    tar xfz kafka.tgz -C /opt/kafka --strip-components 1; \
    wget -nv -O KEYS https://downloads.apache.org/kafka/KEYS; \
    gpg --import KEYS; \
    gpg --batch --verify kafka.tgz.asc kafka.tgz

# Generate JSA files using dynamic CDS for Kafka server start command and Kafka storage format command
RUN /etc/kafka/docker/jsa_launch

FROM rootioinc/common-eclipse-temurin:21-jre-bookworm-slim

# exposed ports
EXPOSE 9092

USER root

# Get kafka from https://archive.apache.org/dist/kafka and pass the url through build arguments
ARG kafka_url
ARG build_date

LABEL org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.build-date="${build_date}" \
      org.label-schema.vcs-url="https://github.com/apache/kafka" \
      maintainer="Apache Kafka"

      RUN set -eux ; \
      apt-get update ; \
      apt-get upgrade -y ; \
      apt-get install -y wget gpg gnupg procps bash ca-certificates ; \
      mkdir -p /opt/kafka ; \
      wget -nv -O kafka.tgz "$kafka_url" || { echo "Download failed"; exit 1; }; \
      wget -nv -O kafka.tgz.asc "$kafka_url.asc" || { echo "Signature download failed"; exit 1; }; \
      tar xfz kafka.tgz -C /opt/kafka --strip-components 1 || { echo "Extraction failed"; exit 1; }; \
      wget -nv -O KEYS https://downloads.apache.org/kafka/KEYS || { echo "KEYS download failed"; exit 1; }; \
      gpg --import KEYS || { echo "GPG key import failed"; exit 1; }; \
      gpg --batch --verify kafka.tgz.asc kafka.tgz || { echo "GPG verification failed"; exit 1; }; \
      mkdir -p /var/lib/kafka/data /etc/kafka/secrets ; \
      mkdir -p /etc/kafka/docker /usr/logs /mnt/shared/config ; \
      adduser --home /home/appuser --disabled-login --shell /bin/bash appuser ; \
      chown appuser:appuser -R /usr/logs /opt/kafka /mnt/shared/config ; \
      chown appuser:root -R /var/lib/kafka /etc/kafka/secrets /etc/kafka ; \
      chmod -R ug+w /etc/kafka /var/lib/kafka /etc/kafka/secrets ; \
      cp /opt/kafka/config/log4j.properties /etc/kafka/docker/log4j.properties ; \
      cp /opt/kafka/config/tools-log4j.properties /etc/kafka/docker/tools-log4j.properties ; \
      cp /opt/kafka/config/kraft/server.properties /etc/kafka/docker/server.properties ; \
      rm kafka.tgz kafka.tgz.asc KEYS ; \
      apt-get remove -y wget gpg; \
      apt-get autoremove -y ; \
      rm -rf /var/lib/apt/lists/*
  
  

COPY --from=build-jsa /opt/kafka/kafka.jsa /opt/kafka/kafka.jsa
COPY --from=build-jsa /opt/kafka/storage.jsa /opt/kafka/storage.jsa
COPY --chown=appuser:appuser resources/common-scripts /etc/kafka/docker
COPY --chown=appuser:appuser launch /etc/kafka/docker/launch

USER appuser

VOLUME ["/etc/kafka/secrets", "/var/lib/kafka/data", "/mnt/shared/config"]

CMD ["/etc/kafka/docker/run"]
