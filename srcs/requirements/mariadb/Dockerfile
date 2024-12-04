FROM debian:bullseye

RUN apt update -y && apt upgrade -y && apt install -y \
	mariadb-server \
	gettext-base

COPY init.sql /etc/mysql/init.sql
COPY 50-server.cnf /etc/mysql/mariadb.conf.d/.
COPY script.sh .

RUN mkdir -p /run/mysqld

RUN chmod +x script.sh

CMD ["./script.sh"]