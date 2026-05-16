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

  printf "${CYAN}%-28s${NC} ${GREEN}[" "$label"

  printf "%0.s█" $(seq 1 $filled)
  printf "%0.s░" $(seq 1 $empty)

  printf "]${NC} ${YELLOW}%3d%%${NC}\n" "$percent"
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

echo -e "${GREEN}Welcome to NETTOOLS V2.0.0${NC}"
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

IFS= read -r -p "Select edition [1-3]: " edition

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

    read -p "Type YES to install Light Nettool: " confirm

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

    read -p "Type YES to install Normal Nettool: " confirm

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
    read -p "Press ENTER to return..." dummy
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
if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  info "Setting up AI environment..."

  python3 -m venv ~/nettool-env

  ~/nettool-env/bin/pip install --upgrade pip >/dev/null 2>&1

  ~/nettool-env/bin/pip install ultralytics opencv-python >/dev/null 2>&1

  ~/nettool-env/bin/pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu >/dev/null 2>&1

  ok "AI environment ready"

fi

if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 not found"
    exit 1
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
# 🔍 VALIDASI FILE NETTOOL
# =========================

if [ "$NETTOOL_MODE" = "LIGHT" ]; then
  [ ! -f light_nettool ] && fail "light_nettool missing in project folder" && exit 1
fi

if [ "$NETTOOL_MODE" = "NORMAL" ]; then
  [ ! -f normal_nettool ] && fail "normal_nettool missing in project folder" && exit 1
fi
info "Preparing launcher"

# =========================
# 🟡 LIGHT NETTOOL
# =========================
if [ "$NETTOOL_MODE" = "LIGHT" ]; then

  [ ! -f light_nettool ] && fail "light_nettool missing" && exit 1

  cp light_nettool /tmp/nettool || {
    fail "Failed to load Light Nettool"
    exit 1
  }

  ok "Light Nettool selected"

fi

# =========================
# 🟢 NORMAL NETTOOL
# =========================
if [ "$NETTOOL_MODE" = "NORMAL" ]; then

  [ ! -f normal_nettool ] && fail "normal_nettool missing" && exit 1

  cp normal_nettool /tmp/nettool || {
    fail "Failed to load Normal Nettool"
    exit 1
  }

  ok "Normal Nettool selected"

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
echo "Thank you for installing NETTOOLS V2.0.0"
echo ""
