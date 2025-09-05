#!/bin/bash
# =====================================================================
# EC2 Bootstrap Script: Node.js + nginx + MongoDB
# Works on Ubuntu 20.04 / 22.04 / 24.04
# =====================================================================

exec > >(tee -a /var/log/ec2_bootstrap.log | logger -t userdata -s 2>/dev/console) 2>&1
set -euxo pipefail

echo "===== Starting EC2 Bootstrap at $(date) ====="

# ---------------------------------------------------------------------
# Base setup
# ---------------------------------------------------------------------
apt-get update -y
apt-get install -y curl gnupg lsb-release ca-certificates build-essential

# ---------------------------------------------------------------------
# Install Node.js (via NodeSource repo instead of NVM)
# ---------------------------------------------------------------------
echo "Installing Node.js 22..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
node -v
npm -v

# ---------------------------------------------------------------------
# Install nginx
# ---------------------------------------------------------------------
echo "Installing nginx..."
apt-get install -y nginx
systemctl enable nginx
systemctl start nginx

if systemctl is-active --quiet nginx; then
  echo "✅ Nginx running successfully!"
else
  echo "❌ Nginx failed to start!"
fi

# ---------------------------------------------------------------------
# Install MongoDB 7.0
# ---------------------------------------------------------------------
echo "Installing MongoDB..."

MONGO_KEY="/usr/share/keyrings/mongodb.gpg"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o "$MONGO_KEY"

echo "deb [ arch=amd64,arm64 signed-by=$MONGO_KEY ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/7.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update -y
apt-get install -y mongodb-org

systemctl enable mongod
systemctl start mongod

if systemctl is-active --quiet mongod; then
  echo "✅ MongoDB installed and running!"
  mongod --version
else
  echo "❌ MongoDB installation failed!"
fi

echo "===== Bootstrap Completed at $(date) ====="
