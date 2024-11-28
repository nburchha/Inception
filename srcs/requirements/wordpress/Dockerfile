FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt install -y \
	php7.4-fpm \
	php7.4-mysqli \
	curl \
	netcat

COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

RUN mkdir /run/php
COPY script.sh /usr/local/bin/script.sh
RUN chmod +x /usr/local/bin/script.sh

CMD ["/usr/local/bin/script.sh"]