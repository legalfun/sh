#!/bin/sh

#define the template.
cat  << EOF
server {
        listen 80;
        listen [::]:80;

        root /var/www/$1/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $1 www.$1;

        location / {
                try_files \$uri \$uri/ =404;
        }
}
EOF