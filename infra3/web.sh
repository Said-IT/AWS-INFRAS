#!/bin/bash

export HTTP_PROXY=http://${web_ip}:3128 
export HTTPS_PROXY=http://${web_ip}:3128
yum update
yum install -y httpd
cat /etc/hostname > sudo tee /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable --now httpd
