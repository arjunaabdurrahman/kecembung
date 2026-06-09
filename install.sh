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

BASE_URL="https://raw.githubusercontent.com/arjunaabdurrahman/kecembung/main"

# =========================
# 📌 VERSION
# =========================

KECEMBUNG_VERSION=$(curl -fsSL "$BASE_URL/version.txt" 2>/dev/null | tr -d '[:space:]')

if [ -z "$KECEMBUNG_VERSION" ]; then
  KECEMBUNG_VERSION="UNKNOWN"
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
echo "              KECEMBUNG INSTALLER"
echo "=================================================="
echo -e "${NC}"

echo -e "${GREEN}Welcome to KECEMBUNG V ${KECEMBUNG_VERSION}${NC}"
echo ""
echo "KECEMBUNG is a modular Linux toolkit"
echo "designed for networking, automation,"
echo "storage utilities, and AI systems."
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
# 📦 COMPONENT SELECTION
# =========================

INSTALL_AI_DETECT=0
INSTALL_AI_TRAIN=0
INSTALL_AI_CHAT=0
INSTALL_SCENARIO=0

while true; do

  echo ""
  echo -e "${CYAN}==================================================${NC}"
  echo -e "${GREEN}           SELECT COMPONENTS${NC}"
  echo -e "${CYAN}==================================================${NC}"
  echo ""
  echo -e "${GREEN}[1] AI Detect${NC}"
  echo "    Object detection via webcam, RTSP, image, or video"
  echo "    Requires: Python venv, ultralytics, opencv, torch"
  echo ""
  echo -e "${GREEN}[2] AI Train${NC}"
  echo "    Train custom YOLO models with your own dataset"
  echo "    Requires: Python venv, ultralytics"
  echo ""
  echo -e "${GREEN}[3] AI Chat${NC}"
  echo "    Local LLM chat assistant powered by Ollama"
  echo "    Requires: Ollama"
  echo ""
  echo -e "${GREEN}[4] Scenario Builder${NC}"
  echo "    Build and run automated command scenarios"
  echo "    Optional: Ollama (for AI scenario generation)"
  echo ""
  echo -e "${CYAN}==================================================${NC}"
  echo -e "${YELLOW}Select components (example: 1 3 4)${NC}"
  echo -e "${YELLOW}Type 'all' to install everything${NC}"
  echo -e "${YELLOW}Or press ENTER to install core only${NC}"
  echo -e "${CYAN}==================================================${NC}"

  IFS= read -r -p "Select: " selection </dev/tty

  # =========================
  # CORE ONLY (ENTER)
  # =========================

  if [ -z "$selection" ]; then
    echo ""
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${GREEN}         SELECTED: CORE ONLY${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo ""
    echo -e "${CYAN}  [~] Networking tools${NC}"
    echo -e "${CYAN}  [~] TCP tools${NC}"
    echo -e "${CYAN}  [~] Storage utilities${NC}"
    echo -e "${CYAN}  [~] USB tools${NC}"
    echo ""
    echo -e "${CYAN}==================================================${NC}"

    IFS= read -r -p "Confirm installation? (YES/no): " confirm </dev/tty

    if [ "$confirm" = "no" ]; then
      clear
      continue
    fi

    break
  fi

  # =========================
  # ALL
  # =========================

  if [ "$selection" = "all" ]; then
    INSTALL_AI_DETECT=1
    INSTALL_AI_TRAIN=1
    INSTALL_AI_CHAT=1
    INSTALL_SCENARIO=1
  else

    valid=0

    for num in $selection; do
      case $num in
        1) INSTALL_AI_DETECT=1; valid=1 ;;
        2) INSTALL_AI_TRAIN=1;  valid=1 ;;
        3) INSTALL_AI_CHAT=1;   valid=1 ;;
        4) INSTALL_SCENARIO=1;  valid=1 ;;
        *)
          warn "Unknown component: $num"
          ;;
      esac
    done

    if [ "$valid" -eq 0 ]; then
      warn "No valid component selected, try again"
      sleep 1
      clear
      continue
    fi

  fi

  # =========================
  # CONFIRM SELECTION
  # =========================

  echo ""
  echo -e "${CYAN}==================================================${NC}"
  echo -e "${GREEN}         SELECTED COMPONENTS${NC}"
  echo -e "${CYAN}==================================================${NC}"
  echo ""

  echo -e "${CYAN}  [~] Core (always included)${NC}"
  [ "$INSTALL_AI_DETECT" -eq 1 ] && echo -e "${GREEN}  [✔] AI Detect${NC}"
  [ "$INSTALL_AI_TRAIN"  -eq 1 ] && echo -e "${GREEN}  [✔] AI Train${NC}"
  [ "$INSTALL_AI_CHAT"   -eq 1 ] && echo -e "${GREEN}  [✔] AI Chat${NC}"
  [ "$INSTALL_SCENARIO"  -eq 1 ] && echo -e "${GREEN}  [✔] Scenario Builder${NC}"

  echo ""
  echo -e "${CYAN}==================================================${NC}"

  IFS= read -r -p "Confirm installation? (YES/no): " confirm </dev/tty

  if [ "$confirm" = "no" ]; then
    clear
    INSTALL_AI_DETECT=0
    INSTALL_AI_TRAIN=0
    INSTALL_AI_CHAT=0
    INSTALL_SCENARIO=0
    continue
  fi

  break

done

clear

# =========================
# 🚀 INSTALL START
# =========================

echo -e "${CYAN}"
echo "=================================================="
echo "            STARTING INSTALLATION"
echo "=================================================="
echo -e "${NC}"

# =========================
# 📦 BASE DEPENDENCIES
# =========================

info "Installing base dependencies"

if apt_install "nmap netcat-openbsd iproute2 dialog figlet wget curl"; then
  ok "Base dependencies installed"
else
  fail "Base dependency installation failed"
  exit 1
fi

# =========================
# 🐍 PYTHON VENV
# =========================

NEED_VENV=0
[ "$INSTALL_AI_DETECT" -eq 1 ] && NEED_VENV=1
[ "$INSTALL_AI_TRAIN"  -eq 1 ] && NEED_VENV=1

AI_ENV="$HOME/kecembung-env"

if [ "$NEED_VENV" -eq 1 ]; then

  echo ""
  info "Setting up Python environment"

  if apt_install "python3 python3-pip python3-venv"; then
    ok "Python installed"
  else
    fail "Python installation failed"
    exit 1
  fi

  if [ ! -d "$AI_ENV" ] || \
     [ ! -x "$AI_ENV/bin/python" ] || \
     [ ! -x "$AI_ENV/bin/pip" ]; then

    rm -rf "$AI_ENV"
    python3 -m venv "$AI_ENV" || {
      fail "Failed to create virtual environment"
      exit 1
    }

    progress_bar 1 3 "Upgrading pip"
    "$AI_ENV/bin/pip" install --upgrade pip >/dev/null 2>&1

    progress_bar 2 3 "Installing AI packages"
    "$AI_ENV/bin/pip" install ultralytics opencv-python \
      --no-cache-dir >/dev/null 2>&1

    if [ "$INSTALL_AI_DETECT" -eq 1 ]; then
      progress_bar 3 3 "Installing torch"
      "$AI_ENV/bin/pip" install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cpu \
        >/dev/null 2>&1
    else
      progress_bar 3 3 "Finalizing"
      sleep 0.5
    fi

    ok "Python environment ready"

  else
    ok "Python environment already exists, skipping"
  fi

fi

# =========================
# 🧠 OLLAMA
# =========================

NEED_OLLAMA=0
[ "$INSTALL_AI_CHAT"  -eq 1 ] && NEED_OLLAMA=1
[ "$INSTALL_SCENARIO" -eq 1 ] && NEED_OLLAMA=1

if [ "$NEED_OLLAMA" -eq 1 ]; then

  echo ""
  info "Checking Ollama..."

  if command -v ollama >/dev/null 2>&1; then
    ok "Ollama already installed"
  else

    # kalau hanya scenario yang dipilih, ollama opsional
    if [ "$INSTALL_AI_CHAT" -eq 0 ] && [ "$INSTALL_SCENARIO" -eq 1 ]; then
      echo ""
      warn "Ollama is optional for Scenario Builder"
      echo "      Without Ollama, AI Scenario feature will be hidden"
      echo ""
      IFS= read -r -p "Install Ollama? (YES/no): " ollama_confirm </dev/tty

      if [ "$ollama_confirm" = "no" ]; then
        warn "Skipping Ollama"
        NEED_OLLAMA=0
      fi
    fi

    if [ "$NEED_OLLAMA" -eq 1 ]; then
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

fi

# =========================
# 📁 CREATE STRUCTURE
# =========================

echo ""
info "Creating KECEMBUNG structure"

mkdir -p "$HOME/.kecembung/ai"
mkdir -p "$HOME/.kecembung/scenarios"
mkdir -p "$HOME/.kecembung/logs"
mkdir -p "$HOME/kecembung_scenarios"
mkdir -p "$HOME/kecembung_logs"

progress_bar 1 3 "Creating folders"
sleep 0.3
progress_bar 2 3 "Preparing structure"
sleep 0.3
progress_bar 3 3 "Done"

ok "Structure created"

# =========================
# 📥 DOWNLOAD MAIN SCRIPT
# =========================

echo ""
info "Downloading KECEMBUNG main script"

curl -fsSL "$BASE_URL/kecembung" -o /tmp/kecembung || {
  fail "Failed to download kecembung"
  exit 1
}

chmod +x /tmp/kecembung
ok "Main script downloaded"

# =========================
# 📥 DOWNLOAD AI DETECT
# =========================

if [ "$INSTALL_AI_DETECT" -eq 1 ]; then

  echo ""
  info "Downloading AI Detect"

  curl -fsSL "$BASE_URL/kecembung_/ai/ai_detect.py" \
    -o "$HOME/.kecembung/ai/ai_detect.py" || {
    fail "Failed to download ai_detect.py"
    exit 1
  }

  ok "AI Detect downloaded"

fi

# =========================
# 📥 DOWNLOAD AI TRAIN
# =========================

if [ "$INSTALL_AI_TRAIN" -eq 1 ]; then

  echo ""
  info "Downloading AI Train"

  curl -fsSL "$BASE_URL/kecembung_/ai/ai_train.py" \
    -o "$HOME/.kecembung/ai/ai_train.py" || {
    fail "Failed to download ai_train.py"
    exit 1
  }

  ok "AI Train downloaded"

fi

# =========================
# 📥 DOWNLOAD SCENARIO BUILDER
# =========================

if [ "$INSTALL_SCENARIO" -eq 1 ]; then

  echo ""
  info "Downloading Scenario Builder"

  curl -fsSL "$BASE_URL/kecembung_/scenario/scenario_builder.sh" \
    -o "$HOME/.kecembung/scenarios/scenario_builder.sh" || {
    fail "Failed to download scenario_builder.sh"
    exit 1
  }

  chmod +x "$HOME/.kecembung/scenarios/scenario_builder.sh"
  ok "Scenario Builder downloaded"

fi

# =========================
# ⚙️ MODE FLAG
# =========================

echo ""
info "Generating mode flag"

MODE_FILE="$HOME/.kecembung_mode"

cat > "$MODE_FILE" <<EOF
AI_DETECT=$INSTALL_AI_DETECT
AI_TRAIN=$INSTALL_AI_TRAIN
AI_CHAT=$INSTALL_AI_CHAT
SCENARIO=$INSTALL_SCENARIO
OLLAMA=$NEED_OLLAMA
EOF

chmod 600 "$MODE_FILE"
ok "Mode flag configured"

# =========================
# 📦 INSTALL COMMAND: bung
# =========================

echo ""
info "Installing 'bung' command"

sudo mv /tmp/kecembung /usr/local/bin/kecembung
sudo chmod +x /usr/local/bin/kecembung

cat > /tmp/bung <<'BUNGSCRIPT'
#!/bin/bash
exec /usr/local/bin/kecembung "$@"
BUNGSCRIPT

sudo mv /tmp/bung /usr/local/bin/bung
sudo chmod +x /usr/local/bin/bung

progress_bar 1 2 "Installing launcher"
sleep 0.5
progress_bar 2 2 "Completing install"

ok "'bung' command installed"

# =========================
# 🔐 SET PASSWORD
# =========================

echo ""
echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN}   SET KECEMBUNG PASSWORD${NC}"
echo -e "${CYAN}==============================${NC}"

PASS_FILE="$HOME/.kecembung_pass"

while true; do

  IFS= read -r -s -p "Create Password: " pass1 </dev/tty
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

ok "Password configured"

# =========================
# 🎉 SUMMARY
# =========================

echo ""
echo -e "${CYAN}==============================${NC}"
echo -e "${GREEN}      INSTALL SUMMARY${NC}"
echo -e "${CYAN}==============================${NC}"
echo ""
echo -e "Version  : ${GREEN}$KECEMBUNG_VERSION${NC}"
echo -e "Command  : ${GREEN}bung${NC}"
echo ""
echo -e "Components:"
echo -e "  ${CYAN}[~] Core${NC}"

if [ "$INSTALL_AI_DETECT" -eq 0 ] && \
   [ "$INSTALL_AI_TRAIN"  -eq 0 ] && \
   [ "$INSTALL_AI_CHAT"   -eq 0 ] && \
   [ "$INSTALL_SCENARIO"  -eq 0 ]; then
  echo -e "  ${CYAN}[~] No additional components${NC}"
else
  [ "$INSTALL_AI_DETECT" -eq 1 ] && echo -e "  ${GREEN}[✔] AI Detect${NC}"   || echo -e "  ${RED}[✘] AI Detect${NC}"
  [ "$INSTALL_AI_TRAIN"  -eq 1 ] && echo -e "  ${GREEN}[✔] AI Train${NC}"    || echo -e "  ${RED}[✘] AI Train${NC}"
  [ "$INSTALL_AI_CHAT"   -eq 1 ] && echo -e "  ${GREEN}[✔] AI Chat${NC}"     || echo -e "  ${RED}[✘] AI Chat${NC}"
  [ "$INSTALL_SCENARIO"  -eq 1 ] && echo -e "  ${GREEN}[✔] Scenario Builder${NC}" || echo -e "  ${RED}[✘] Scenario Builder${NC}"
fi

echo ""
echo -e "${CYAN}==============================${NC}"

loading_bar "Finalizing KECEMBUNG..."
sleep 1

echo ""
echo -e "${GREEN}"
echo "=================================================="
echo "              INSTALL COMPLETE"
echo "=================================================="
echo -e "${NC}"

echo ""
echo -e "${CYAN}You can now launch KECEMBUNG using:${NC}"
echo ""
echo -e "${GREEN}  bung${NC}"
echo ""
echo -e "Thank you for installing KECEMBUNG V ${KECEMBUNG_VERSION}"
echo ""
