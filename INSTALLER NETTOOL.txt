#!/bin/bash

# =========================
# 🎨 COLORS
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# =========================
# 🔐 INSTALL LOCK SYSTEM
# =========================
LOCK_FILE="$HOME/.nettool_installed"

# =========================
# 🚫 BLOCK REINSTALL
# =========================
if [ -f "$LOCK_FILE" ]; then
  echo -e "${YELLOW}[!] NETTOOLS sudah terinstall.${NC}"
  echo -e "${CYAN}Gunakan: nettool update (jika tersedia)${NC}"
  exit 1
fi

# =========================
# 🎬 ANIMATION FUNCTION
# =========================
animate() {
  echo -n "$1"
  for i in {1..5}; do
    echo -n "."
    sleep 0.3
  done
  echo ""
}

# =========================
# 🚀 START INSTALL
# =========================
clear
echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN}   NETTOOLS INSTALLER${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""

animate "[~] Checking system"

# =========================
# 📦 DEPENDENCIES
# =========================
animate "[~] Installing dependencies"

sudo apt update -y >/dev/null 2>&1

sudo apt install -y \
nmap \
netcat-openbsd \
iproute2 \
dialog \
figlet \
python3 \
python3-pip >/dev/null 2>&1

# =========================
# 🤖 AI ENV SETUP
# =========================
animate "[~] Setting AI environment"

python3 -m venv ~/yolo-env >/dev/null 2>&1

source ~/yolo-env/bin/activate
pip install --quiet ultralytics opencv-python

# =========================
# 📁 FOLDER SETUP
# =========================
animate "[~] Creating folders"

mkdir -p ~/nettools_scenarios
mkdir -p ~/nettools_logs

# =========================
# 📥 COPY FILES
# =========================
animate "[~] Installing core files"

sudo cp nettool /usr/local/bin/nettool
cp scenario_builder.sh ~/
cp ai_detect.py ~/
cp ai_train.py ~/

# =========================
# 🔐 PERMISSION
# =========================
chmod +x /usr/local/bin/nettool
chmod +x ~/scenario_builder.sh
chmod +x ~/ai_detect.py
chmod +x ~/ai_train.py

# =========================
# 🔗 SYSTEM LINK
# =========================
if [ ! -f /usr/bin/nettool ]; then
  sudo ln -s /usr/local/bin/nettool /usr/bin/nettool
fi

# =========================
# 🧠 INSTALL LOCK CREATE
# =========================
echo "installed" > "$LOCK_FILE"

# =========================
# 🎉 DONE ANIMATION
# =========================
echo ""
animate "[✔] Finalizing installation"
sleep 0.5

echo -e "${GREEN}"
echo "=============================="
echo "  INSTALL COMPLETE"
echo "=============================="
echo -e "${NC}"

echo -e "${CYAN}Run: nettool${NC}"
echo ""

