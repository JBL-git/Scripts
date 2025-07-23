#!/bin/bash

# Creates Vic, Jac (sudo) and Srv (no sudo) with random passwords

set -e

generate_password() {
  openssl rand -base64 14
}

hash_password() {
  openssl passwd -6 "$1"
}

# Generate passwords
VIC_RAW=$(generate_password)
JAC_RAW=$(generate_password)
SRV_RAW=$(generate_password)

# Generate hashes
VIC_PASS=$(hash_password "$VIC_RAW")
JAC_PASS=$(hash_password "$JAC_RAW")
SRV_PASS=$(hash_password "$SRV_RAW")

# Create users
sudo useradd -m -s /bin/bash -G wheel -p "$VIC_PASS" Vic
sudo useradd -m -s /bin/bash -G wheel -p "$JAC_PASS" Jac
sudo useradd -m -s /bin/bash -p "$SRV_PASS" Srv

# Show credentials
echo
echo "======================"
echo "User Passwords (save these!):"
echo "Vic: $VIC_RAW"
echo "Jac: $JAC_RAW"
echo "Srv: $SRV_RAW"
echo "======================"
