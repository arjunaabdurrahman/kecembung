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
# 📊 PROGRESS BAR
# =========================

progress_bar() {

  local current=$1
  local total=$2
  local label="$3"

  local width=28

  local percent=$(( current * 100 / total ))
  local filled=$(( width * current / total ))
  local empty=$(( width - filled ))

  local fill=$(printf "%${filled}s")
  local space=$(printf "%${empty}s")

  printf "\r${CYAN}%-24s${NC} [${GREEN}%s${NC}%s] ${YELLOW}%3d%%${NC}" \
    "$label" \
    "${fill// /█}" \
    "${space// /░}" \
    "$percent"

  if [ "$current" -eq "$total" ]; then
    echo ""
  fi
}

# =========================
# 🎬 LOADING
# =========================

loading() {

  local text="$1"

  printf "\n${CYAN}%s...${NC}\n" "$text"
}

apt_install() {

  local pkgs="$1"

  loading "[~] Installing packages"

  progress_bar 1 4 "Updating apt"

  sudo apt update -y >/dev/null 2>&1 || return 1

  progress_bar 2 4 "Installing packages"

  sudo apt install -y $pkgs >/dev/null 2>&1 || return 1

  progress_bar 3 4 "Finishing"
  
  sleep 0.5

  progress_bar 4 4 "Complete"

  return 0
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

progress_bar 1 5 "Creating venv"

python3 -m venv ~/nettool-env >/dev/null 2>&1 || {
  fail "Failed create venv"
  exit 1
}

progress_bar 2 5 "Updating pip"

"$HOME/nettool-env/bin/pip" install --upgrade pip --quiet

progress_bar 3 5 "Installing AI"

"$HOME/nettool-env/bin/pip" install ultralytics opencv-python \
  --no-cache-dir --quiet || {
  fail "AI setup failed"
  exit 1
}

progress_bar 4 5 "Installing Torch"

"$HOME/nettool-env/bin/pip" install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cpu --quiet || {
  fail "Torch install failed"
  exit 1
}

progress_bar 5 5 "Verifying"

if "$HOME/nettool-env/bin/python" -c "import ultralytics, cv2" >/dev/null 2>&1; then
  ok "AI environment ready"
else
  fail "Import check failed"
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

progress_bar 1 4 "Downloading nettool"
wget -q "$REPO_URL/nettool" -O /tmp/nettool
sleep 0.2
progress_bar 2 4 "Downloading ai_detect"
wget -q "$REPO_URL/ai_detect.py" -O ~/ai_detect.py
sleep 0.2
progress_bar 3 4 "Downloading ai_train"
wget -q "$REPO_URL/ai_train.py" -O ~/ai_train.py
sleep 0.2
progress_bar 4 4 "Downloading scenario"
wget -q "$REPO_URL/scenario_builder.sh" -O ~/scenario_builder.sh
sleep 0.2
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
  echo -e "${CYAN}[~] Silakan buat password untuk NETTOOLS${NC}"
  echo ""

  while true; do
    read -s -p "Buat password NETTOOLS: " pass < /dev/tty
    echo ""

    if [ -z "$pass" ]; then
      echo -e "${YELLOW}[!] Password tidak boleh kosong${NC}"
      continue
    fi

    read -s -p "Konfirmasi password: " pass2 < /dev/tty
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
