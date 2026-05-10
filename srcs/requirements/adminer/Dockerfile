FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y php7.4 php7.4-mysql wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

RUN wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O adminer.php && \
    chown -R www-data:www-data /var/www/html/adminer.php && \
    chmod 755 /var/www/html/adminer.php

EXPOSE 8080

CMD ["php", "-S", "[::]:8080", "-t", "/var/www/html"]
