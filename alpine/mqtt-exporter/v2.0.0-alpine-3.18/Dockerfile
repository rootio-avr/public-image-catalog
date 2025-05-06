FROM python:3.11.5-alpine

LABEL org.opencontainers.image.title=mqtt_exporter
LABEL org.opencontainers.image.description="Prometheus exporter for MQTT."
LABEL org.opencontainers.image.vendor="Frederic Hemberger"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.source=https://github.com/fhemberger/mqtt_exporter

# Install git to clone the repository
RUN apk add --no-cache git

# Set working directory
WORKDIR /usr/src/app

# Clone the repository at the specified tag (v2.0.0)
RUN git clone --branch v2.0.0 --depth 1 https://github.com/fhemberger/mqtt_exporter.git . 

# Add a system user without a home directory or login shell
RUN adduser --system --no-create-home --shell /usr/sbin/nologin mqtt_exporter

# Upgrade setuptools before installing other dependencies
RUN pip install --no-cache-dir --upgrade setuptools==70.0.0

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements-frozen.txt

# Use the non-root user
USER mqtt_exporter

EXPOSE 9344

# Set the entrypoint to run the exporter
ENTRYPOINT [ "python3", "-u", "/usr/src/app/mqtt_exporter.py" ]
