#!/bin/bash
set -e

cd /var/www/html

curl -o /usr/local/bin/wp -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x /usr/local/bin/wp
wp core download --allow-root

# Wait for MariaDB to start
until nc -z -w50 mariadb 3306; do
    echo "Waiting for MariaDB to start..."
    sleep 1
done

# Create wp-config.php
wp config create \
    --dbname=$WP_DB_NAME \
    --dbuser=$WP_DB_USER \
    --dbpass=$WP_DB_PASSWORD \
    --dbhost=$WP_DB_HOST \
    --allow-root

# Install WordPress
wp core install \
    --url=$DOMAIN_NAME \
    --title=$WP_TITLE \
    --admin_user=$WP_ADMIN_USER \
    --admin_password=$WP_ADMIN_PASSWORD \
    --admin_email=$WP_ADMIN_EMAIL \
    --allow-root

# Change ownership of the files
chown -R www-data:www-data /var/www/html

# Start PHP-FPM
php-fpm7.4 -F
