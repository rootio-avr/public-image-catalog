# Stage 1: Frontend build

FROM rootioinc/common-node:22.14.0-bookworm-slim AS superset-node

ARG NPM_BUILD_CMD="build"
ENV NODE_OPTIONS=--max-old-space-size=1024 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential python3 && rm -rf /var/lib/apt/lists/*

WORKDIR /app/superset-frontend

COPY superset-frontend/package*.json ./
RUN npm ci

COPY superset-frontend ./
RUN npm run ${NPM_BUILD_CMD}

# Stage 2: Build & install deps
FROM rootioinc/common-python:3.10-bookworm-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libldap2-dev \
    libsasl2-dev \
    default-libmysqlclient-dev \
    libecpg-dev \
    libffi-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*


COPY setup.py MANIFEST.in README.md ./
COPY superset ./superset

# Copy frontend metadata required by setup.py
COPY superset-frontend/package.json superset-frontend/

# Copy requirements last
COPY requirements ./requirements

# Now install requirements safely
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements/local.txt


# Stage 3: Final lean runtime image

FROM rootioinc/common-python:3.10-bookworm-slim AS superset

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    FLASK_APP="superset.app:create_app()" \
    PYTHONPATH="/app/pythonpath" \
    SUPERSET_HOME="/app/superset_home" \
    SUPERSET_PORT=8088 \
    SUPERSET_ENV=production

WORKDIR /app

RUN adduser --disabled-password --home /app/superset_home --gecos "" superset && \
    mkdir -p /app/pythonpath /app/superset/static /app/superset_home && \
    chown -R superset:superset /app

# Copy installed Python environment from builder
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

# Superset source
COPY setup.py MANIFEST.in README.md ./
COPY superset-frontend/package.json superset-frontend/
COPY superset ./superset

# Compile app and translations
RUN pip install -e . && \
    flask fab babel-compile --target superset/translations && \
    chown -R superset:superset superset/translations

# Copy frontend assets
COPY --from=superset-node /app/superset/static/assets ./superset/static/assets

COPY --chmod=755 docker/run-server.sh /usr/bin/
USER superset

EXPOSE ${SUPERSET_PORT}
HEALTHCHECK CMD curl -f "http://localhost:${SUPERSET_PORT}/health"
CMD ["/usr/bin/run-server.sh"]
