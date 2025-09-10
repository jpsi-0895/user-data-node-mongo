#!/bin/bash
set -euo pipefail

# ===================================================
# EC2 User Data Bootstrap
# Installs: Node.js (clean), MongoDB, NVM (latest)
# Logs stored in: /var/log/user-data.log
# ===================================================

# --- Logging setup ---
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE | logger -t user-data -s 2>/dev/console) 2>&1

echo "[INFO] Starting EC2 initialization..."

# --- Update system ---
echo "[INFO] Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ===================================================
# 1. Node.js (Clean Install via NodeSource)
# ===================================================
NODE_VERSION="20"   # LTS version

echo "[INFO] Removing old Node.js packages..."
sudo apt-get remove -y nodejs libnode-dev npm || true
sudo apt-get autoremove -y
sudo apt-get purge -y nodejs libnode-dev npm || true

echo "[INFO] Cleaning apt cache..."
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update -y

echo "[INFO] Installing prerequisites for Node.js..."
sudo apt-get install -y curl ca-certificates gnupg lsb-release

echo "[INFO] Adding NodeSource GPG key..."
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
  sudo gpg --dearmor -o /usr/share/keyrings/nodesource.gpg

echo "[INFO] Adding Node.js ${NODE_VERSION}.x repository..."
echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" \
  | sudo tee /etc/apt/sources.list.d/nodesource.list

echo "[INFO] Installing Node.js..."
sudo apt-get update -y
sudo apt-get install -y nodejs build-essential

echo "[INFO] Node.js version: $(node -v)"
echo "[INFO] NPM version: $(npm -v)"

# ===================================================
# 2. MongoDB Installation (8.0 series)
# ===================================================
MONGO_VERSION="8.0"
UBUNTU_CODENAME=$(lsb_release -sc)
KEYRING_PATH="/usr/share/keyrings/mongodb-server-${MONGO_VERSION}.gpg"
LIST_PATH="/etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list"

echo "[INFO] Adding MongoDB GPG key..."
curl -fsSL "https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc" | \
    sudo gpg --dearmor -o "${KEYRING_PATH}"

echo "[INFO] Adding MongoDB repo for ${UBUNTU_CODENAME}..."
echo "deb [ arch=amd64,arm64 signed-by=${KEYRING_PATH} ] https://repo.mongodb.org/apt/ubuntu ${UBUNTU_CODENAME}/mongodb-org/${MONGO_VERSION} multiverse" | \
    sudo tee "${LIST_PATH}"

echo "[INFO] Installing MongoDB..."
sudo apt-get update -y
sudo apt-get install -y mongodb-org

echo "[INFO] Configuring MongoDB permissions..."
sudo mkdir -p /var/lib/mongodb /var/log/mongodb
sudo chown -R mongodb:mongodb /var/lib/mongodb /var/log/mongodb

echo "[INFO] Enabling and starting MongoDB..."
sudo systemctl daemon-reload
sudo systemctl enable --now mongod

echo "[INFO] MongoDB version: $(mongod --version | head -n 1)"

# ===================================================
# 3. Node Version Manager (NVM) Setup
# ===================================================
NVM_VERSION="v0.39.7"
DEFAULT_NODE="20"

echo "[INFO] Installing NVM..."
if [ ! -d "$HOME/.nvm" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
else
  echo "[INFO] NVM already present, updating..."
  cd "$HOME/.nvm" && git fetch --tags origin && git checkout "${NVM_VERSION}"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "[INFO] Installing Node.js ${DEFAULT_NODE}.x via NVM..."
nvm install ${DEFAULT_NODE}
nvm alias default ${DEFAULT_NODE}
nvm use default

echo "[INFO] Final Node.js version (via NVM): $(node -v)"
echo "[INFO] Final NPM version (via NVM): $(npm -v)"

# ===================================================
# Done
# ===================================================
echo "[SUCCESS] EC2 initialization completed successfully!"
