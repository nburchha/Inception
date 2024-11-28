#!/bin/bash

envsubst '${DOMAIN}' < "/etc/nginx/sites-available/default" > "/etc/nginx/sites-available/default.tmp"
mv /etc/nginx/sites-available/default.tmp /etx/nginx/sites-available/default

openssl req -x509 \
			-nodes \
			-days 365 \
			-newkey rsa:2048 \
			-keyout /etc/ssl/private/nginx-selfsigned.key \
			-out /etc/ssl/certs/nginx-selfsigned.crt \
			-subj "/C=DE/ST=BW/L=Heilbronn/O=42HN/CN=$DOMAIN"

nginx -g "daemon off;"