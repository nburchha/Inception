FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/*

# Configure Redis to listen on all interfaces, limit memory, and set eviction policy for WP cache
RUN sed -i "s|bind 127.0.0.1 -::1|bind 0.0.0.0|g" /etc/redis/redis.conf && \
    sed -i "s|# maxmemory <bytes>|maxmemory 256mb|g" /etc/redis/redis.conf && \
    sed -i "s|# maxmemory-policy noeviction|maxmemory-policy allkeys-lru|g" /etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "--protected-mode", "no"]
