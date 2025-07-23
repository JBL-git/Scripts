#!/bin/bash

echo "==> Updating system..."
sudo yum update -y

echo "==> Installing firewalld, tmux, openssh, openssl..."
sudo yum install tmux openssh openssl
sudo yum install firewalld -y

echo "==> Starting and enabling firewalld..."
sudo systemctl enable --now firewalld

echo "==> Resetting firewalld rules..."
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=42420/tcp

echo "==> Reloading and listing all ports for firewall..."
sudo firewall-cmd --reload

sudo firewall-cmd --list-all

echo "==> Done"
