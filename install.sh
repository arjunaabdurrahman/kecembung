#!/bin/bash

# =========================
# 🎨 COLORS
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main"

LOCK_FILE="$HOME/.nettool_installed"

# =========================
# 🎬 LOADING
# =========================
loading() {
  echo -ne "${CYAN}$1${NC}"
  for i in {1..3}; do
    echo -ne "."
    sleep 0.3
  done
  echo ""
}

ok() {
  echo -e "${GREEN}[✔] $1${NC}"
}

fail() {
  echo -e "${RED}[✘] $1${NC}"
}

# =========================
# 🚫 REINSTALL CHECK
# =========================
if [ -f "$LOCK_FILE" ]; then
  echo -e "${YELLOW}[!] NETTOOLS sudah terinstall${NC}"
  read -p "Reinstall? (YES/no): " confirm
  if [ "$confirm" = "YES" ]; then
    echo "[~] Cleaning old installation..."
    sudo rm -f /usr/local/bin/nettool
    sudo rm -f /usr/bin/nettool
    rm -f "$HOME/.nettool_installed"
  else
    echo "[~] Install dibatalkan"
    exit 0
  fi
fi

# =========================
# 🚀 START
# =========================
clear
echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN}   NETTOOLS INSTALLER${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""

loading "[~] Checking system"

# =========================
# 📦 DEPENDENCIES
# =========================
loading "[~] Installing dependencies"

if sudo apt update -y >/dev/null 2>&1 && \
   sudo apt install -y nmap netcat-openbsd iproute2 dialog figlet python3 python3-pip wget >/dev/null 2>&1
then
  ok "Dependencies installed"
else
  fail "Failed install dependencies"
  exit 1
fi

# =========================
# 🤖 AI ENV
# =========================
loading "[~] Setting AI environment"

python3 -m venv ~/yolo-env >/dev/null 2>&1
source ~/yolo-env/bin/activate

if pip install --quiet ultralytics opencv-python --no-cache-dir; then
  pip install --quiet torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
  rm -rf ~/.cache/pip >/dev/null 2>&1
  ok "AI environment ready"
else
  fail "AI setup failed"
fi

# =========================
# 📁 FOLDER
# =========================
loading "[~] Creating folders"

mkdir -p ~/nettools_scenarios
mkdir -p ~/nettools_logs

ok "Folders ready"

# =========================
# 📥 DOWNLOAD FILES (FIX CURL MODE)
# =========================
loading "[~] Downloading core files"

wget -q "$REPO_URL/nettool" -O /tmp/nettool
wget -q "$REPO_URL/ai_detect.py" -O ~/ai_detect.py
wget -q "$REPO_URL/ai_train.py" -O ~/ai_train.py
wget -q "$REPO_URL/scenario_builder.sh" -O ~/scenario_builder.sh

if [ ! -f /tmp/nettool ] || [ ! -f ~/ai_detect.py ] || [ ! -f ~/ai_train.py ]; then
  fail "Download failed"
  exit 1
fi
ok "Files downloaded"

# =========================
# 📦 INSTALL
# =========================
loading "[~] Installing system command"

sudo mv /tmp/nettool /usr/local/bin/nettool

chmod +x /usr/local/bin/nettool
chmod +x ~/scenario_builder.sh
chmod +x ~/ai_detect.py
chmod +x ~/ai_train.py

ok "Core installed"

# =========================
# 🔗 LINK
# =========================
loading "[~] Creating system link"

if [ ! -f /usr/bin/nettool ]; then
  sudo ln -s /usr/local/bin/nettool /usr/bin/nettool
fi

ok "Command linked"

# =========================
# 🔐 PASSWORD SETUP
# =========================
if [ ! -f "$HOME/.nettool_pass" ]; then
  echo ""
  read -s -p "Buat password NETTOOLS: " pass
  echo ""
  
  if [ -z "$pass" ]; then
    fail "Password tidak boleh kosong"
    exit 1
  fi

  echo -n "$pass" | sha256sum | awk '{print $1}' > "$HOME/.nettool_pass"
  ok "Password berhasil diset"
fi

# =========================
# 🔐 LOCK
# =========================
echo "installed" > "$LOCK_FILE"

# =========================
# 🎉 DONE
# =========================
echo ""
loading "[~] Finalizing"

echo -e "${GREEN}"
echo "=============================="
echo "   INSTALL COMPLETE 🚀"
echo "=============================="
echo -e "${NC}"

echo -e "${CYAN}Run: nettool${NC}"
echo ""
