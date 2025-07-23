#!/bin/bash

echo "==> Updating system..."
sudo pacman -Syu

echo "==> Installing firewalld, tmux, openssh, openssl..."
sudo pacman -S install tmux openssh openssl
sudo pacman -S install firewalld

echo "==> Starting and enabling firewalld..."
sudo systemctl enable --now firewalld

echo "==> Resetting firewalld rules..."
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=42420/tcp

echo "==> Reloading and listing all ports for firewall..."
sudo firewall-cmd --reload

sudo firewall-cmd --list-all

echo "==> Done"
