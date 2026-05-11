FROM alpine:3.23

# Install Go and Git
RUN apk add --no-cache go git && \
    mkdir -p /app && cd /app && \
    # 1. Clone a specific release tag, not the moving master branch
    git clone --depth 1 -b v5.17.0 https://github.com/TwiN/gatus.git . && \
    # 2. Limit compilation threads and disable CGO to save memory/prevent OOM
    CGO_ENABLED=0 go build -p 1 -o gatus . && \
    mv gatus /usr/local/bin/gatus && \
    cd / && rm -rf /app && \
    # Clean up build dependencies to keep the image small
    apk del go git

COPY config.yaml /config/config.yaml

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/gatus"]