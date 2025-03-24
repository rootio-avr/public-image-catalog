# Update Go dependencies
RUN go get -u golang.org/x/crypto && \
    go get -u golang.org/x/net && \
    go mod tidy