#!/bin/bash

# =========================
# 🎨 COLORS
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

trap 'echo ""; echo -e "${YELLOW}[!] Installer interrupted${NC}"; exit 1' SIGINT

# =========================
# 📁 SCRIPT DIRECTORY
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =========================
# 🌐 GITHUB SOURCE
# =========================

BASE_URL="https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main"

# =========================
# 📌 VERSION
# =========================

NETTOOL_VERSION=$(curl -fsSL "$BASE_URL/version.txt" 2>/dev/null | tr -d '[:space:]')

if [ -z "$NETTOOL_VERSION" ]; then
  NETTOOL_VERSION="UNKNOWN"
fi

# =========================
# 🧰 FUNCTIONS
# =========================

ok() {
  echo -e "${GREEN}[✔] $1${NC}"
}

fail() {
  echo -e "${RED}[✘] $1${NC}"
}

info() {
  echo -e "${CYAN}[~] $1${NC}"
}

warn() {
  echo -e "${YELLOW}[!] $1${NC}"
}

loading_bar() {

  local text="$1"

  echo ""
  echo -e "${CYAN}$text${NC}"

  for i in 20 40 60 80 100; do

    local filled=$(( i / 4 ))
    local empty=$(( 25 - filled ))

    printf "\r${GREEN}["
    printf "%0.s█" $(seq 1 $filled)
    printf "%0.s░" $(seq 1 $empty)
    printf "]${NC} ${YELLOW}%s%%${NC}" "$i"

    sleep 0.2

  done

  echo ""
}

progress_bar() {

  local current=$1
  local total=$2
  local label="$3"

  local width=30

  local percent=$(( current * 100 / total ))
  local filled=$(( width * current / total ))
  local empty=$(( width - filled ))

  printf "\r${CYAN}%-28s${NC} ${GREEN}[" "$label"

  printf "%0.s█" $(seq 1 $filled)

  printf "%0.s░" $(seq 1 $empty)

  printf "]${NC} ${YELLOW}%3d%%${NC}" "$percent"

  if [ "$current" -eq "$total" ]; then
    echo ""
  fi
}

apt_install() {

  local pkgs="$1"

  echo ""
  info "Installing required packages"

  progress_bar 1 4 "Updating package list"

  sudo apt update -y >/dev/null 2>&1 || return 1

  progress_bar 2 4 "Installing packages"

  sudo apt install -y $pkgs >/dev/null 2>&1 || return 1

  progress_bar 3 4 "Finalizing installation"

  sleep 1

  progress_bar 4 4 "Complete"

  return 0
}

# =========================
# 🚀 START
# =========================

clear

echo -e "${CYAN}"
echo "=================================================="
echo "                NETTOOLS INSTALLER"
echo "=================================================="
echo -e "${NC}"

echo -e "${GREEN}Welcome to NETTOOLS V ${NETTOOL_VERSION}${NC}"
echo ""
echo "NETTOOLS is a multifunction Linux toolkit"
echo "designed for networking, automation,"
echo "storage utilities, and future AI systems."
echo ""

sleep 1

loading_bar "Loading installer environment..."
loading_bar "Checking system compatibility..."
loading_bar "Preparing installation wizard..."
sleep 0.3
clear

# =========================
# 🔐 SUDO AUTH
# =========================

echo ""
info "Administrator permission required"

sudo -v || {
  fail "Sudo authentication failed"
  exit 1
}

ok "Authentication success"

sleep 1
clear

# =========================
# 📦 EDITION MENU
# =========================

while true; do

echo ""
echo -e "${CYAN}==================================================${NC}"
echo -e "${GREEN}                 SELECT MODEL${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""

echo -e "${GREEN}[1] Light Nettool${NC}"
echo "    Lightweight version for low-storage systems"
echo "    Basic networking and storage utilities"
echo ""

echo -e "${GREEN}[2] Normal Nettool${NC}"
echo "    Full networking suite with AI support"
echo "    Recommended for 75GB+ systems"
echo ""

echo -e "${YELLOW}[3] Power Nettool${NC}"
echo "    Advanced AI, RAG, automation, and LLM systems"
echo "    Currently unavailable"
echo ""

IFS= read -r -p "Select edition [1-3]: " edition </dev/tty

if [ -z "$edition" ]; then
  continue
fi

case $edition in

  1)

    echo ""
    echo -e "${CYAN}================ LIGHT NETTOOL ================${NC}"
    echo ""

    echo -e "${GREEN}Recommended For:${NC}"
    echo "- Lightweight laptops"
    echo "- Small SSD/HDD systems"
    echo "- Virtual machines"
    echo ""

    echo -e "${GREEN}Included Features:${NC}"
    echo "- TCP tools"
    echo "- Storage utilities"
    echo "- Scenario tools"
    echo "- System utilities"
    echo ""

    echo -e "${RED}Not Included:${NC}"
    echo "- AI packages"
    echo "- LLM support"
    echo "- Heavy dependencies"
    echo ""

    IFS= read -r -p "Type YES to install Light Nettool: " confirm </dev/tty

    if [ "$confirm" = "YES" ]; then
      NETTOOL_MODE="LIGHT"
      break
    else
      clear
      continue
    fi
    
    ;;

  2)

    echo ""
    echo -e "${CYAN}=============== NORMAL NETTOOL ===============${NC}"
    echo ""

    echo -e "${GREEN}Recommended For:${NC}"
    echo "- Daily Linux users"
    echo "- Large storage systems"
    echo "- AI experimentation"
    echo ""

    echo -e "${GREEN}Included Features:${NC}"
    echo "- Full networking suite"
    echo "- AI tools"
    echo "- Scenario automation"
    echo "- Extended storage utilities"
    echo ""

    echo -e "${YELLOW}Recommended Storage:${NC}"
    echo "- 75GB or higher"
    echo ""

    IFS= read -r -p "Type YES to install Normal Nettool: " confirm </dev/tty

    if [ "$confirm" = "YES" ]; then
      NETTOOL_MODE="NORMAL"
      break
    else
      clear
      continue
    fi

    ;;

  3)

    echo ""
    echo -e "${CYAN}================ POWER NETTOOL ================${NC}"
    echo ""

    echo -e "${RED}[LOCKED / COMING SOON]${NC}"
    echo ""

    echo "- Local LLM integration"
    echo "- RAG system"
    echo "- Advanced AI workflows"
    echo "- Multi-stage automation"
    echo "- Advanced scenario engine"
    echo "- Multi-machine management"
    echo ""

    echo -e "${YELLOW}Power Nettool is currently unavailable.${NC}"
    echo ""

    echo ""
    IFS= read -r -p "Press ENTER to return..." dummy </dev/tty
    clear
    ;;

  *)

    echo ""
    echo -e "${RED}[!] Invalid option${NC}"
    echo ""

    ;;

esac

done

# =========================
# 🚀 INSTALL START
# =========================

clear

echo -e "${CYAN}"
echo "=================================================="
echo "              STARTING INSTALLATION"
echo "=================================================="
echo -e "${NC}"

echo ""
info "Selected Edition : $NETTOOL_MODE"

sleep 1

# =========================
# 📦 DEPENDENCIES
# =========================

if [ "$NETTOOL_MODE" = "LIGHT" ]; then

  if apt_install "nmap netcat-openbsd iproute2 dialog figlet wget"; then
    ok "Dependencies installed"
  else
    fail "Dependency installation failed"
    exit 1
  fi

fi

if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  if apt_install "nmap netcat-openbsd iproute2 dialog figlet wget python3 python3-pip"; then
    ok "Dependencies installed"
  else
    fail "Dependency installation failed"
    exit 1
  fi

fi

# =========================
# 🤖 AI ENV (NORMAL)
# =========================

check_ai_backend() {

  AI_ENV="$HOME/nettool-env"

  # cek folder env
  if [ ! -d "$AI_ENV" ]; then
    return 1
  fi

  # cek python
  if [ ! -x "$AI_ENV/bin/python" ]; then
    return 1
  fi

  # cek pip
  if [ ! -x "$AI_ENV/bin/pip" ]; then
    return 1
  fi

  # cek dependency python
  "$AI_ENV/bin/python" -c "
import ultralytics
import cv2
import torch
" >/dev/null 2>&1

  return $?
}

if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  AI_ENV="$HOME/nettool-env"

  info "Checking AI backend..."

  if check_ai_backend; then

    ok "AI backend already installed"
    info "Skipping AI installation"

  else

    warn "AI backend missing/corrupted"
    info "Installing AI backend..."

    rm -rf "$AI_ENV"

    python3 -m venv "$AI_ENV"

    "$AI_ENV/bin/pip" install --upgrade pip \
      >/dev/null 2>&1

    "$AI_ENV/bin/pip" install ultralytics opencv-python \
      --no-cache-dir >/dev/null 2>&1

    "$AI_ENV/bin/pip" install torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cpu \
      >/dev/null 2>&1

    ok "AI environment ready"

  fi

  # =========================
  # 🧠 OLLAMA CHECK
  # =========================

  info "Checking Ollama..."

  if command -v ollama >/dev/null 2>&1; then

    ok "Ollama already installed"

  else

    warn "Ollama not found"
    info "Installing Ollama..."

    curl -fsSL https://ollama.com/install.sh | sh >/dev/null 2>&1

    if [ $? -eq 0 ]; then
      ok "Ollama installed"
    else
      fail "Failed to install Ollama"
      exit 1
    fi

  fi

fi

# =========================
# 📁 CREATE STRUCTURE
# =========================

echo ""
info "Creating NETTOOLS structure"

mkdir -p ~/nettools_scenarios
mkdir -p ~/nettools_logs
mkdir -p ~/nettools_modules

progress_bar 1 3 "Creating folders"

sleep 0.5

progress_bar 2 3 "Preparing launcher"

sleep 0.5

progress_bar 3 3 "Finalizing structure"

ok "Folders created"

# =========================
# 📝 PREPARE NETTOOL
# =========================

echo ""

# =========================
# 🟡 LIGHT NETTOOL
# =========================

if [ "$NETTOOL_MODE" = "LIGHT" ]; then

  wget -q -O /tmp/nettool "$BASE_URL/light_nettool" || {
    fail "Failed to download Light Nettool"
    exit 1
  }

  ok "Light Nettool downloaded"

fi

# =========================
# 🟢 NORMAL NETTOOL
# =========================

if [ "$NETTOOL_MODE" = "NORMAL" ]; then
  
  # =========================
  # DOWNLOAD MAIN NETTOOL
  # =========================

  wget -q -O /tmp/nettool "$BASE_URL/normal_nettool" || {
    fail "Failed to download Normal Nettool"
    exit 1
  }

  ok "Normal Nettool downloaded"
  
  echo ""
  info "Installing AI modules"

  mkdir -p "$HOME/.nettool/ai"
  mkdir -p "$HOME/.nettool/scenarios"

# =========================
# AI DETECT
# =========================

  progress_bar 1 4 "Downloading AI Detect"

  curl -sSL \
  https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main/nettools/ai/ai_detect.py \
  -o "$HOME/.nettool/ai/ai_detect.py" || {
    fail "Failed to download ai_detect.py"
    exit 1
  }

  sleep 0.3

# =========================
# TRAIN
# =========================

  progress_bar 2 4 "Downloading Trainer"

  curl -sSL \
  https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main/nettools/ai/ai_train.py \
  -o "$HOME/.nettool/ai/ai_train.py" || {
      fail "Failed to download ai_train.py"
      exit 1
  }

# =========================
# SCENARIO BUILDER
# =========================

  progress_bar 3 4 "Downloading Scenario Builder"

  curl -sSL \
  https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main/nettools/scenario/scenario_builder.sh \
  -o "$HOME/.nettool/scenarios/scenario_builder.sh" || {
    fail "Failed to download scenario_builder.sh"
    exit 1
  }

  chmod +x "$HOME/.nettool/scenarios/scenario_builder.sh"

  sleep 0.3

# =========================
# COMPLETE
# =========================

progress_bar 4 4 "Finalizing AI modules"

ok "AI modules installed"

fi

# =========================
# 🔒 FINAL VALIDATION
# =========================
if [ ! -f /tmp/nettool ]; then
  fail "Launcher preparation failed"
  exit 1
fi

chmod +x /tmp/nettool

ok "Launcher ready"

# =========================
# ⚙️ MODE FLAG GENERATOR
# =========================

info "Generating system mode flag"

MODE_FILE="$HOME/.nettool_mode"

# LIGHT MODE
if [ "$NETTOOL_MODE" = "LIGHT" ]; then

  echo "AI_ENABLED=0" > "$MODE_FILE"
  echo "MODE=LIGHT" >> "$MODE_FILE"

fi

# NORMAL MODE
if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  echo "AI_ENABLED=1" > "$MODE_FILE"
  echo "MODE=NORMAL" >> "$MODE_FILE"

fi

# =========================
# 🔒 SECURITY LOCK
# =========================
chmod 600 "$MODE_FILE"

# =========================
# 🧪 VALIDATION
# =========================
if [ ! -s "$MODE_FILE" ]; then
  fail "Mode file generation failed"
  exit 1
fi

ok "Mode system configured"

# =========================
# 📦 INSTALL COMMAND
# =========================

echo ""
info "Installing NETTOOLS command"

sudo mv /tmp/nettool /usr/local/bin/nettool

sudo chmod +x /usr/local/bin/nettool

progress_bar 1 2 "Installing launcher"

sleep 0.5

progress_bar 2 2 "Completing install"

ok "NETTOOLS installed"

# =========================
# 🔗 LINK SYSTEM
# =========================

echo ""
info "Creating system link"

sudo ln -sf /usr/local/bin/nettool /usr/bin/nettool

ok "Command linked"

# =========================
# 🔐 SET NETTOOLS PASSWORD
# =========================

echo ""
echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN} SET NETTOOLS PASSWORD${NC}"
echo -e "${CYAN}==============================${NC}"

PASS_FILE="$HOME/.nettool_pass"

while true; do

  IFS= read -r -s -p "Create NETTOOLS Password: " pass1 </dev/tty
  echo ""

  IFS= read -r -s -p "Confirm Password: " pass2 </dev/tty
  echo ""

  if [ -z "$pass1" ]; then

    echo -e "${RED}[!] Password cannot be empty${NC}"
    continue

  fi

  if [ "$pass1" != "$pass2" ]; then

    echo -e "${RED}[!] Password mismatch${NC}"
    continue

  fi

  break

done

PASS_HASH=$(echo -n "$pass1" | sha256sum | awk '{print $1}')

echo "$PASS_HASH" > "$PASS_FILE"

chmod 600 "$PASS_FILE"

ok "NETTOOLS password configured"

# =========================
# 🎉 DONE
# =========================

echo ""
echo "=============================="
echo " INSTALL SUMMARY"
echo "=============================="
echo "Edition : $NETTOOL_MODE"
echo "Command : nettool"
echo "Python AI Env : $( [ -d ~/nettool-env ] && echo READY || echo NONE )"
echo "=============================="

loading_bar "Finalizing NETTOOL function"
sleep 1

echo ""
echo -e "${GREEN}"
echo "=================================================="
echo "               INSTALL COMPLETE"
echo "=================================================="
echo -e "${NC}"

echo ""
echo -e "${CYAN}Installed Edition : $NETTOOL_MODE${NC}"
echo ""
echo "You can now launch NETTOOLS using:"
echo ""
echo -e "${GREEN}nettool${NC}"
echo ""
echo "Thank you for installing NETTOOLS V ${NETTOOL_VERSION}"
echo ""



