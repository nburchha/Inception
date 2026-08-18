FROM debian:bookworm

RUN apt update -y && apt upgrade -y && apt install -y \
	php8.2-fpm \
	php8.2-mysqli \
	php8.2-curl \
	php8.2-gd \
	php8.2-intl \
	php8.2-mbstring \
	php8.2-imagick \
	php8.2-dom \
	php8.2-zip \
	php8.2-redis \
	curl

COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN mkdir -p /run/php
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]