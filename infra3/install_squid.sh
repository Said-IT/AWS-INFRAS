#!/bin/bash

# Mise à jour des packages
sudo yum update

# Installation de Squid
sudo yum install -y squid

# Configuration de Squid
cat <<EOF | sudo tee /etc/squid/squid.conf
http_port 3128
http_access allow all

# Configuration pour rediriger vers le load balancer
#acl lb_dst dst ${alb} 
#http_access allow lb_dst
#tcp_outgoing_address ${alb} lb_dst
EOF

# Redémarrage de Squid
sudo systemctl restart squid

# Activation de Squid au démarrage
sudo systemctl enable squid
