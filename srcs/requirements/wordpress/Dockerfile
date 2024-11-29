FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt install -y \
	php7.4-fpm \
	php7.4-mysqli \
	php7.4-curl \
	php7.4-gd \
	php7.4-intl \
	php7.4-mbstring \
	php7.4-imagick \
	php7.4-dom \
	php7.4-zip \
	curl

COPY www.conf /etc/php/7.4/fpm/pool.d/www.conf

RUN mkdir /run/php
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]