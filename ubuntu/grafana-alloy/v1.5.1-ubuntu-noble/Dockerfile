# syntax=docker/dockerfile:1.4
# ------------------------------------------------------------------------------
# Dockerbuild
#DOCKER_BUILDKIT=1 docker buildx build   --build-arg REPO_TAG=v1.5.1   
#--build-arg VERSION=v1.5.1   -t grafana-alloy:v1.5.1   .
#
# ------------------------------------------------------------------------------
# Stage 1: Clone the GitHub repo at tag v1.5.1 and build
FROM --platform=$BUILDPLATFORM grafana/alloy-build-image:v0.1.6 as build

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG RELEASE_BUILD=1
ARG VERSION
ARG GOEXPERIMENT
ARG REPO_URL=https://github.com/grafana/alloy.git
ARG REPO_TAG=v1.5.1

# Clone the specified tag from GitHub
RUN git clone --depth 1 --branch $REPO_TAG $REPO_URL /src/alloy

WORKDIR /src/alloy
COPY go.mod ./
RUN go mod tidy

# Build the UI before building Alloy
RUN --mount=type=cache,target=/src/alloy/web/ui/node_modules,sharing=locked \
   make generate-ui

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v} \
    RELEASE_BUILD=${RELEASE_BUILD} VERSION=${VERSION} \
    GO_TAGS="netgo builtinassets promtail_journal_enabled" \
    GOEXPERIMENT=${GOEXPERIMENT} \
    make alloy

# Stage 2: Final runtime image
FROM public.ecr.aws/ubuntu/ubuntu:noble

ARG UID=473
ARG USERNAME="alloy"

LABEL org.opencontainers.image.source="https://github.com/grafana/alloy"

RUN apt-get update \
 && apt-get install -qy libsystemd-dev tzdata ca-certificates \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build --chown=$UID /src/alloy/build/alloy /bin/alloy
COPY --from=build --chown=$UID /src/alloy/example-config.alloy /etc/alloy/config.alloy

RUN groupadd --gid $UID $USERNAME
RUN useradd -m -u $UID -g $UID $USERNAME

RUN mkdir -p /var/lib/alloy/data
RUN chown -R $USERNAME:$USERNAME /var/lib/alloy
RUN chmod -R 770 /var/lib/alloy

ENTRYPOINT ["/bin/alloy"]
ENV ALLOY_DEPLOY_MODE=docker
CMD ["run", "/etc/alloy/config.alloy", "--storage.path=/var/lib/alloy/data"]
