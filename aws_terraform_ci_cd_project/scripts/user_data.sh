#!/bin/bash
apt update -y
apt install -y nginx
systemctl start nginx
systemctl enable nginx
echo "<h1>Deployed via Terraform</h1>" > /var/www/html/index.html
