#!/bin/bash

envsubst < /etc/mysql/init.sql > /etc/mysql/tmp.sql
mv /etc/mysql/tmp.sql /etc/mysql/init.sql

mysql_install_db
mysqld