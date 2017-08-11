#!/bin/bash

sudo apt-get update
sudo apt-get dist-upgrade -y
add-apt-repository -y ppa:nginx/stable
sudo apt-get install -y nginx mariadb-server mariadb-client php php-common php-cgi php-fpm php-gd php-cli php-pear php-mcrypt php-mysql php-gd git vim
mysqladmin -u root password 'your_password_here'
/etc/init.d/nginx stop
/etc/init.d/php5-fpm stop

sed -i 's/^;cgi.fix_pathinfo.*$/cgi.fix_pathinfo = 0/g' /etc/php/fpm/php.ini

## Settings for DVWA to be extra vuln :)
sed -i 's/allow_url_include = Off/allow_url_include = On/g' /etc/php/7.0/fpm/php.ini
sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/g' /etc/php/7.0/fpm/php.ini
sed -i 's/safe_mode = On/safe_mode = Off/g' /etc/php/7.0/fpm/php.ini
echo "magic_quotes_gpc = Off" >> /etc/php/7.0/fpm/php.ini
sed -i 's/display_errors = Off/display_errors = On/g' /etc/php/7.0/fpm/php.ini

sed -i 's/^;security.limit_extensions.*$/security.limit_extensions = .php .php3 .php4 .php5 .php7/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/^listen.owner.*$/listen.owner = www-data/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/^listen.group.*$/listen.group = www-data/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/^;listen.mode.*$/listen.mode = 0660/g' /etc/php/7.0/fpm/pool.d/www.conf

cat << 'EOF' > /etc/nginx/sites-enabled/default
server
{
    listen  80;
    root /var/www/html;
    index index.php index.html index.htm;
    #server_name localhost
    location "/"
    {
        index index.php index.html index.htm;
        #try_files $uri $uri/ =404;
    }

    location ~ \.php$
    {
        include /etc/nginx/fastcgi_params;
        fastcgi_pass unix:/var/run/php/php7.0-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }
}
EOF

cat <<'EOF' > /root/.my.cnf
[client]
user="root"
password="your_password_here"
EOF

service mysql restart
systemctl restart php7.0-fpm
systemctl restart nginx

mysql -BNe "CREATE DATABASE dvwa;"
mysql -BNe "GRANT ALL ON *.* TO 'dvwa_root'@'localhost' IDENTIFIED BY 'your_password_here';"
if [[ ! -d "/var/www/html" ]]; 
then 
      mkdir -p /var/www;
      ln -s /usr/share/nginx/html /var/www/html;
      chown -R www-data. /var/www/html;
fi

rm /var/www/html/*.html

cd /var/www/html && git clone https://github.com/RandomStorm/DVWA.git && chown -R www-data. ./ && mv ./DVWA/* . && cp config/config.inc.php.dist config/config.inc.php && chmod 777 ./hackable/uploads/; chmod 777 ./external/phpids/0.6/lib/IDS/tmp/phpids_log.txt
sed -i '/db_user/ s/root/dvwa_root/' /var/www/html/config/config.inc.php
sed -i '/db_password/ s/p@ssw0rd/your_password_here/'
sed -i "/recaptcha_public_key/ s/''/'your_google_recaptcha_public_key_here'/" /var/www/html/config/config.inc.php
sed -i "/recaptcha_private_key/ s/''/'your_google_recaptcha_private_key_here'/" /var/www/html/config/config.inc.php

