# Docker file - multi stage build
# Step 1: Build Stage - Use Golang image as the builder
FROM golang:1.23.3-bookworm AS builder

RUN apt-get update && apt-get install -y wget

RUN wget https://golang.org/dl/go1.23.3.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz \
    && rm go1.23.3.linux-amd64.tar.gz

# Step 2: Final Runtime Stage - Use a minimal runtime image based on debian:bookworm-slim
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libc6 \
    && rm -rf /var/lib/apt/lists/*

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH

COPY --from=builder /usr/local/go /usr/local/go

RUN go version

CMD ["bash"]
