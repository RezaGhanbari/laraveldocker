#!/bin/bash
if [ $1 == "php-fpm" ]; then
        shift
        cat >/etc/nginx/sites-available/default <<EOL
server {
        listen   80;

        root /var/www/public;
        index index.php index.html index.htm;

        server_name _;

	error_page 504 @error;

        location / {
                try_files \$uri \$uri/ /index.php?\$query_string;
        }

        location ~ \.php$ {
                try_files \$uri /index.php =404;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                include fastcgi_params;
		fastcgi_read_timeout 100;
        }

	location @error {
                add_header 'Access-Control-Allow-Origin' '*' always;
        }

}
EOL
        # Nginx conf
        cat >/etc/nginx/nginx.conf <<EOL
user www-data;
worker_processes auto;
pid /run/nginx.pid;
daemon off;

events {
    worker_connections  1024;
}


http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        #tcp_nopush     on;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        gzip on;
        gzip_http_version  1.1;
        gzip_comp_level    5;
        gzip_min_length    256;
        gzip_proxied       any;
        gzip_vary          on;
        gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/rss+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/svg+xml
        image/x-icon
        text/css
        text/plain
        text/x-component;

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}
EOL
        cat >/etc/php/7.0/fpm/php-fpm.conf <<EOL
[global]
error_log = /proc/self/fd/2
daemonize = no
include=/etc/php/7.0/fpm/pool.d/*.conf
EOL
	cat >/etc/php/7.0/fpm/pool.d/www.conf <<EOL
[www]
user = www-data
group = www-data
listen = /var/run/php-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
clear_env = no
EOL
sed -i "s/memory_limit = 128M/memory_limit = 1024M/" /etc/php/7.0/fpm/php.ini
#php artisan config:cache
#php artisan route:cache
#php artisan optimize
nginx &
env /usr/sbin/php-fpm7.0
elif [ $1 == "queue" ]; then
	php /var/www/artisan queue:work redis --sleep=3 --tries=3
elif [ $1 == "schedule" ]; then
	while true; do
		sleep 60
		/usr/bin/php /var/www/artisan schedule:run
	done
elif [ $1 == "cancelpending" ]; then
        while true; do
                sleep 900
                /usr/bin/php /var/www/artisan cancel:payment-pending
        done
elif [ $1 == "bash" ]; then
        bash
fi
