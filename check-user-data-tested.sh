#!/bin/bash
# =====================================================================
# 🚀 Service Health Check Script
# Checks status, uptime, logs, and versions for Node.js, npm, nginx, MongoDB
# Author: Harsh Rajotya (Pro Version)
# =====================================================================

set -euo pipefail
IFS=$'\n\t'

LOG_FILE="/var/log/service_health_check.log"
exec > >(tee -a "$LOG_FILE") 2>&1

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; RESET="\e[0m"
ok(){ echo -e "${GREEN}[OK]${RESET} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${RESET} $1"; }
fail(){ echo -e "${RED}[FAIL]${RESET} $1"; }

echo "===== Service Health Check at $(date) ====="

# === Check Node.js & npm ===
if command -v node >/dev/null 2>&1; then
  NODE_VER=$(node -v)
  NPM_VER=$(npm -v)
  ok "Node.js is installed: $NODE_VER"
  ok "npm is installed: $NPM_VER"
else
  fail "Node.js is not installed"
fi

# === Check nginx ===
SERVICE="nginx"
if systemctl is-active --quiet $SERVICE; then
  ok "nginx service is running"
  systemctl status $SERVICE --no-pager | grep "Active:" || true
  echo "Uptime:"
  ps -o etime= -p "$(pidof nginx | awk '{print $1}')" || warn "Could not fetch uptime"
  echo "Last 10 logs:"
  journalctl -u nginx -n 10 --no-pager || warn "No logs found"
else
  fail "nginx service is not running"
fi

# === Check MongoDB ===
SERVICE="mongod"
if systemctl is-active --quiet $SERVICE; then
  ok "MongoDB service is running"
  MONGO_VER=$(mongod --version | head -n 1)
  ok "MongoDB version: $MONGO_VER"
  systemctl status $SERVICE --no-pager | grep "Active:" || true
  echo "Uptime:"
  ps -o etime= -p "$(pidof mongod)" || warn "Could not fetch uptime"
  echo "Last 10 logs:"
  journalctl -u mongod -n 10 --no-pager || warn "No logs found"
else
  fail "MongoDB service is not running"
fi

echo "===== Service Health Check Completed at $(date) ====="
