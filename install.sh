#!/bin/bash

# =========================
# 🎨 COLORS
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok() {
  echo -e "${GREEN}[✔] $1${NC}"
}

fail() {
  echo -e "${RED}[✘] $1${NC}"
}

REPO_URL="https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main"

LOCK_FILE="$HOME/.nettool_installed"

trap "echo -e '\n${YELLOW}[!] Installer interrupted safely${NC}'; exit 1" SIGINT

# =========================
# 🎬 LOADING
# =========================

loading() {
  local text="$1"
  local total=20

  echo -e "${CYAN}${text}${NC}"

  echo -ne "["
  for ((i=0; i<total; i++)); do
    echo -ne "█"
    sleep 0.03
  done
  echo -e "] done"
}

spinner() {
  local pid=$1
  local text="$2"

  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

  echo -ne "${CYAN}${text}${NC} "

  while kill -0 $pid 2>/dev/null; do
    for i in $(seq 0 8); do
      echo -ne "\r${CYAN}${text} ${spin:$i:1}${NC}"
      sleep 0.1
    done
  done

  echo -e "\r${GREEN}${text} ✔${NC}"
}

apt_install() {
  local pkgs="$1"

  echo -e "${CYAN}[~] Installing: $pkgs${NC}"

  (
    sudo apt update -y >/dev/null 2>&1
    sudo apt install -y $pkgs >/dev/null 2>&1
  ) &

  pid=$!

  spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

  i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % 10 ))
    echo -ne "\r${CYAN}[~] Installing ${spin:$i:1} ${NC}"
    sleep 0.1
  done

  wait $pid
  exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo -e "\r${GREEN}[✔] Installation complete        ${NC}"
    return 0
  else
    echo -e "\r${RED}[✘] Installation failed         ${NC}"
    return 1
  fi
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

# =========================
# 📦 DEPENDENCIES
# =========================

loading "[~] Checking system"

if apt_install "nmap netcat-openbsd iproute2 dialog figlet python3 python3-pip wget"; then
  ok "Dependencies installed"
else
  fail "Failed install dependencies"
  exit 1
fi

# =========================
# 🤖 AI ENV
# =========================
loading "[~] Setting AI environment"

python3 -m venv ~/nettool-env >/dev/null 2>&1

if python3 -m venv ~/nettool-env >/dev/null 2>&1; then

  "$HOME/nettool-env/bin/pip" install --upgrade pip --quiet

  if "$HOME/nettool-env/bin/pip" install ultralytics opencv-python --no-cache-dir --quiet; then
    "$HOME/nettool-env/bin/pip" install torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cpu --quiet

    if "$HOME/nettool-env/bin/python" -c "import ultralytics, cv2" >/dev/null 2>&1; then
      ok "AI environment ready"
    else
      fail "Import check failed"
    fi

  else
    fail "AI setup failed"
  fi

else
  fail "Failed to create venv"
  exit 1
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

  while true; do
    read -s -p "Buat password NETTOOLS: " pass
    echo ""

    if [ -z "$pass" ]; then
      echo -e "${YELLOW}[!] Password tidak boleh kosong, coba lagi${NC}"
      continue
    fi

    read -s -p "Konfirmasi password: " pass2
    echo ""

    if [ "$pass" != "$pass2" ]; then
      echo -e "${RED}[!] Password tidak sama, ulangi${NC}"
      continue
    fi

    echo -n "$pass" | sha256sum | awk '{print $1}' > "$HOME/.nettool_pass"
    ok "Password berhasil diset"
    break
  done
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
