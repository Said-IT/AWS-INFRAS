#!/bin/bash

export HTTP_PROXY=http://${web_ip}:3128 
export HTTPS_PROXY=http://${web_ip}:3128
yum update
yum install -y httpd
sudo sh -c "cat /etc/hostname > /var/www/html/index.html"
sudo systemctl start httpd
sudo systemctl enable --now httpd
