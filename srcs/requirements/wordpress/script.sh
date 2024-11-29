#!/bin/bash
cd /var/www/html

curl -o /usr/local/bin/wp -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp
wp core download --allow-root

# Creating wordpress config
wp config create \
	--dbname=$WP_DB_NAME \
	--dbuser=$WP_DB_USER \
	--dbpass=$WP_DB_PASSWORD \
	--dbhost=$WP_DB_HOST \
	--allow-root
# Installing wordpress
wp core install \
	--url=$DOMAIN \
	--title=$WP_TITLE \
	--admin_user=$WP_ADMIN_USER \
	--admin_password=$WP_ADMIN_PASSWORD \
	--admin_email=$WP_ADMIN_EMAIL \
	--allow-root

wp user create \
	$WP_USER \
	$WP_USER_EMAIL \
	--role=author \
	--user_pass=$WP_USER_PASSWORD \
	--allow-root

wp config set WP_CACHE true --raw --allow-root

chown -R www-data:www-data /var/www/html

php-fpm7.4 -F
