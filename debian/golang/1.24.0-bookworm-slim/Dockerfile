# Step 1: Builder Stage - base image with Go 1.24.0
FROM golang:1.24.0-bookworm AS builder

# You can build your Go application here if needed
# WORKDIR /app
# COPY . .
# RUN go build -o myapp

# Step 2: Runtime Stage - minimal base with Go installed from builder
FROM debian:bookworm-slim AS runtime

# Install only required dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libc6 \
    && rm -rf /var/lib/apt/lists/*

# Set Go environment variables
ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH

# Copy the Go installation from builder (Go 1.24.0)
COPY --from=builder /usr/local/go /usr/local/go

# (Optional) Verify Go installation
RUN go version

# Start bash for interactive use (or replace with your actual binary)
CMD ["bash"]
