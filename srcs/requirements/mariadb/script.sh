#!/bin/bash

envsubst < /etc/mysql/init.sql > /etc/mysql/tmp.sql
mv /etc/mysql/tmp.sql /etc/mysql/init.sql

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mysql_install_db
fi

exec mysqld