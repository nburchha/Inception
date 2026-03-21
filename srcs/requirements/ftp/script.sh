#!/bin/bash

# Create empty directory for secure chroot required by vsftpd
mkdir -p /var/run/vsftpd/empty

# Set default values if not provided in .env
FTP_USER=${FTP_USER:-ftpuser}
FTP_PASSWORD=${FTP_PASSWORD:-ftppassword}

# Create user if it doesn't exist
if ! id "$FTP_USER" &>/dev/null; then
    # Add user with no home directory creation (it will use /var/www/html), 
    # but make sure they're part of www-data to play nicely with WP
    useradd -m -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    
    # Add to userlist to allow login
    echo "$FTP_USER" | tee -a /etc/vsftpd.userlist
    
    # Add to www-data group for WordPress compatibility
    usermod -aG www-data "$FTP_USER"
fi

# Fix ownership so FTP user can upload/download nicely
# Since the local root is /var/www/html, ensure they have access.
# If WP container chowns this to www-data:www-data, we are fine 
# as long as we give group write permissions or change owner to FTP user.
chown -R $FTP_USER:www-data /var/www/html
chmod -R 775 /var/www/html

# Start vsftpd in foreground
exec /usr/sbin/vsftpd /etc/vsftpd.conf
