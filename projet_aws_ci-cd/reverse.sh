#!/bin/bash

sudo yum install -y nginx
sudo service nginx start
sudo service nginx enable

# Configuration du reverse proxy

cat <<EOL | sudo tee /etc/nginx/conf.d/reverse-proxy.conf
upstream backend {
    server ${web1_ip}:80;
    server ${web2_ip}:80;
    server ${web3_ip}:80;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend;
    }
}
EOL
# Redémarrage de Nginx pour appliquer la configuration
sudo service nginx restart

