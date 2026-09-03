#!/bin/bash

# =========================
# 🚀 KECEMBUNG UPDATE ENGINE
# =========================

# =========================
# 🎨 COLORS
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =========================
# ⚙️ BASIC CONFIG
# =========================
set +e
set -o pipefail

# =========================
# 🔄 UPDATE MODE CHECK
# =========================
UPDATE_MODE="${KECEMBUNG_UPDATE_MODE:-0}"

if [ "$UPDATE_MODE" -eq 1 ]; then
  # Skip welcome, skip sudo auth, skip password
  # Langsung lompat ke install component berdasarkan ENV
  INSTALL_AI_DETECT="${INSTALL_AI_DETECT:-0}"
  INSTALL_AI_TRAIN="${INSTALL_AI_TRAIN:-0}"
  INSTALL_AI_CHAT="${INSTALL_AI_CHAT:-0}"
  INSTALL_SCENARIO="${INSTALL_SCENARIO:-0}"
  INSTALL_OFFENSIVE="${INSTALL_OFFENSIVE:-0}"
else
  # Normal install flow
  clear
  echo -e "${CYAN}"
  echo "   ██████╗███████╗███╗   ███╗██████╗ ██╗   ██╗███╗   ██╗ ██████╗ "
  echo "  ██╔════╝██╔════╝████╗ ████║██╔══██╗██║   ██║████╗  ██║██╔════╝ "
  echo "  ██║     █████╗  ██╔████╔██║██████╔╝██║   ██║██╔██╗ ██║██║  ███╗"
  echo "  ██║     ██╔══╝  ██║╚██╔╝██║██╔══██╗██║   ██║██║╚██╗██║██║   ██║"
  echo "  ╚██████╗███████╗██║ ╚═╝ ██║██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝"
  echo "   ╚═════╝╚══════╝╚═╝     ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ "
  echo -e "${NC}"
  sleep 1
fi

# =========================
# 📋 SOURCE MODE FLAGS
# =========================
MODE_FILE="$HOME/.kecembung_mode"

AI_DETECT_FLAG=0
AI_TRAIN_FLAG=0
AI_CHAT_FLAG=0
SCENARIO_FLAG=0
OLLAMA_FLAG=0
OFFENSIVE_FLAG=0
NEXUS_FLAG=0

if [ -f "$MODE_FILE" ]; then
  source "$MODE_FILE"
  AI_DETECT_FLAG="${AI_DETECT:-0}"
  AI_TRAIN_FLAG="${AI_TRAIN:-0}"
  AI_CHAT_FLAG="${AI_CHAT:-0}"
  SCENARIO_FLAG="${SCENARIO:-0}"
  OLLAMA_FLAG="${OLLAMA:-0}"
  OFFENSIVE_FLAG="${OFFENSIVE:-0}"
  NEXUS_FLAG="${NEXUS:-0}"
fi

# Install flags — default 0 dulu
INSTALL_AI_DETECT="${INSTALL_AI_DETECT:-0}"
INSTALL_AI_TRAIN="${INSTALL_AI_TRAIN:-0}"
INSTALL_AI_CHAT="${INSTALL_AI_CHAT:-0}"
INSTALL_SCENARIO="${INSTALL_SCENARIO:-0}"
INSTALL_OFFENSIVE="${INSTALL_OFFENSIVE:-0}"
INSTALL_NEXUS="${INSTALL_NEXUS:-0}"

# =========================
# 📁 KECEMBUNG PATH
# =========================
BASE_DIR="$HOME/.kecembung"

AI_DIR="$BASE_DIR/ai"
SCENARIO_DIR="$BASE_DIR/scenarios"
OFFENSIVE_DIR="$BASE_DIR/offensive"
NEXUS_DIR="$BASE_DIR/nexus"
UPDATE_DIR="$BASE_DIR/update"

mkdir -p "$UPDATE_DIR"

# =========================
# 🌐 UPDATE CONFIG
# =========================
REPO_URL="https://raw.githubusercontent.com/arjunaabdurrahman/kecembung/main"

VERSION_URL="$REPO_URL/version.txt"
CHANGELOG_URL="$REPO_URL/changelog.txt"

SCRIPT_URL="$REPO_URL/kecembung"

AI_DETECT_URL="$REPO_URL/kecembung_/ai/ai_detect.py"
AI_TRAIN_URL="$REPO_URL/kecembung_/ai/ai_train.py"
AI_CHAT_URL="$REPO_URL/kecembung_/ai/ai_chat.py"

SCENARIO_URL="$REPO_URL/kecembung_/scenario/scenario_builder.sh"
OFFENSIVE_URL="$REPO_URL/kecembung_/offensive/offensive_tools.sh"
NEXUS_URL="$REPO_URL/kecembung_/nexus/nexus.sh"

# =========================
# 📂 TARGET FILES
# =========================
MAIN_SCRIPT="/usr/local/bin/kecembung"

AI_DETECT_FILE="$AI_DIR/ai_detect.py"
AI_TRAIN_FILE="$AI_DIR/ai_train.py"
AI_CHAT_FILE="$AI_DIR/ai_chat.py"

SCENARIO_FILE="$SCENARIO_DIR/scenario_builder.sh"
OFFENSIVE_FILE="$OFFENSIVE_DIR/offensive_tools.sh"
NEXUS_FILE="$NEXUS_DIR/nexus.sh"

# =========================
# 📥 TEMP FILES
# =========================
TMP_MAIN="$UPDATE_DIR/kecembung"

TMP_AI_DETECT="$UPDATE_DIR/ai_detect.py"
TMP_AI_TRAIN="$UPDATE_DIR/ai_train.py"
TMP_AI_CHAT="$UPDATE_DIR/ai_chat.py"

TMP_SCENARIO="$UPDATE_DIR/scenario_builder.sh"
TMP_OFFENSIVE="$UPDATE_DIR/offensive_tools.sh"
TMP_NEXUS="$UPDATE_DIR/nexus.sh"

# =========================
# 🛡️ CTRL+C PROTECTION
# =========================
trap_ctrlc() {
  echo ""
  echo -e "${RED}[!] UPDATE DIBATALKAN${NC}"
  rm -rf "$UPDATE_DIR"
  echo -e "${YELLOW}[~] Cleanup selesai${NC}"
  sleep 2
  clear
  exit 1
}

trap trap_ctrlc SIGINT

# =========================
# 🧠 UI HELPER
# =========================
print_line() {
  echo -e "${CYAN}========================================${NC}"
}

print_title() {
  clear
  print_line
  echo -e "${GREEN}        KECEMBUNG UPDATE ENGINE${NC}"
  print_line
}

# =========================
# 📊 PROGRESS BAR
# =========================
progress_bar() {
  local percent=$1
  local text="$2"

  local done=$((percent / 2))
  local left=$((50 - done))

  printf "\r${CYAN}["
  printf "%0.s#" $(seq 1 $done)
  printf "%0.s-" $(seq 1 $left)
  printf "]${NC} %s%% | %s" "$percent" "$text"

  if [ "$percent" -ge 100 ]; then
    echo ""
  fi
}

# =========================
# 🌐 INTERNET CHECK
# =========================
check_internet() {
  progress_bar 5 "Checking internet"

  ping -c 1 8.8.8.8 >/dev/null 2>&1

  if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}[!] Tidak ada koneksi internet${NC}"
    exit 1
  fi

  progress_bar 10 "Internet OK"
  sleep 1
}

# =========================
# 🔍 VALIDATE UPDATE SERVER
# =========================
validate_server() {
  progress_bar 15 "Connecting update server"

  HTTP_STATUS=$(curl -o /dev/null -s \
    -w "%{http_code}" \
    --max-time 10 \
    "$VERSION_URL")

  if [ "$HTTP_STATUS" != "200" ]; then
    echo ""
    echo -e "${RED}[!] Update server tidak valid (HTTP $HTTP_STATUS)${NC}"
    exit 1
  fi

  progress_bar 20 "Server validated"
  sleep 1
}

# =========================
# 💡 CEK KOMPONEN BELUM INSTALL
# =========================
check_missing_components() {
  echo ""
  print_line
  echo -e "${CYAN}  CEK KOMPONEN BELUM TERINSTALL${NC}"
  print_line
  echo ""

  # Reset install flags
  INSTALL_AI_DETECT=0
  INSTALL_AI_TRAIN=0
  INSTALL_AI_CHAT=0
  INSTALL_SCENARIO=0
  INSTALL_OFFENSIVE=0

  # Hitung berapa komponen yang belum terinstall
  MISSING_COUNT=0
  [ "$AI_DETECT_FLAG"  -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} AI Detect        : belum terinstall"; ((MISSING_COUNT++)); }
  [ "$AI_TRAIN_FLAG"   -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} AI Train         : belum terinstall"; ((MISSING_COUNT++)); }
  [ "$AI_CHAT_FLAG"    -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} AI Chat          : belum terinstall"; ((MISSING_COUNT++)); }
  [ "$SCENARIO_FLAG"   -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} Scenario Builder : belum terinstall"; ((MISSING_COUNT++)); }
  [ "$OFFENSIVE_FLAG"  -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} Offensive Tools  : belum terinstall"; ((MISSING_COUNT++)); }
  [ "$NEXUS_FLAG"      -eq 0 ] && { echo -e "  ${YELLOW}[-]${NC} NEXUS            : belum terinstall"; ((MISSING_COUNT++)); }

  # Kalau semua sudah terinstall
  if [ "$MISSING_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}[✔]${NC} Semua komponen sudah terinstall"
    echo ""
    return
  fi

  echo ""
  IFS= read -r -p "Install komponen yang belum ada? (Y/n): " ans
  ans="${ans:-Y}"

  if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
    echo -e "${YELLOW}[~] Melewati install komponen baru${NC}"
    return
  fi

  echo ""

  # Tanya satu per satu hanya yang belum terinstall
  if [ "$AI_DETECT_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install AI Detect? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_AI_DETECT=1
  fi

  if [ "$AI_TRAIN_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install AI Train? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_AI_TRAIN=1
  fi

  if [ "$AI_CHAT_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install AI Chat? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_AI_CHAT=1
  fi

  if [ "$SCENARIO_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install Scenario Builder? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_SCENARIO=1
  fi

  if [ "$OFFENSIVE_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install Offensive Tools? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_OFFENSIVE=1
  fi
  
  if [ "$NEXUS_FLAG" -eq 0 ]; then
    IFS= read -r -p "  Install NEXUS? (Y/n): " a
    a="${a:-Y}"
    [ "$a" = "Y" ] || [ "$a" = "y" ] && INSTALL_NEXUS=1
  fi
}

# =========================
# ⚠️ USER CONFIRMATION
# =========================
confirm_update() {
  echo ""
  print_line

  CURRENT_VERSION=$(grep 'CURRENT_VERSION=' "$MAIN_SCRIPT" 2>/dev/null | head -1 | cut -d'"' -f2)
  [ -z "$CURRENT_VERSION" ] && CURRENT_VERSION="unknown"

  LATEST_VERSION=$(curl -s --max-time 5 "$VERSION_URL" | tr -d ' \n\r')

  echo -e "${YELLOW}Version sekarang : ${NC}$CURRENT_VERSION"
  echo -e "${GREEN}Version terbaru  : ${NC}$LATEST_VERSION"

  print_line

  echo ""
  echo -e "${BLUE}Perubahan terbaru:${NC}"
  echo ""
  curl -s --max-time 5 "$CHANGELOG_URL"
  echo ""

  print_line

  echo ""
  echo -e "${CYAN}Komponen yang akan diproses:${NC}"
  echo ""

  # Main script — selalu diupdate
  echo -e "  ${GREEN}[✔]${NC} kecembung (main script)"

  # AI Detect
  if [ "$AI_DETECT_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} AI Detect        (update)"
  elif [ "$INSTALL_AI_DETECT" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} AI Detect        (install baru)"
  else
    echo -e "  ${RED}[-]${NC} AI Detect        (dilewati)"
  fi

  # AI Train
  if [ "$AI_TRAIN_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} AI Train         (update)"
  elif [ "$INSTALL_AI_TRAIN" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} AI Train         (install baru)"
  else
    echo -e "  ${RED}[-]${NC} AI Train         (dilewati)"
  fi

  # AI Chat
  if [ "$AI_CHAT_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} AI Chat          (update)"
  elif [ "$INSTALL_AI_CHAT" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} AI Chat          (install baru)"
  else
    echo -e "  ${RED}[-]${NC} AI Chat          (dilewati)"
  fi

  # Scenario Builder
  if [ "$SCENARIO_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} Scenario Builder (update)"
  elif [ "$INSTALL_SCENARIO" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} Scenario Builder (install baru)"
  else
    echo -e "  ${RED}[-]${NC} Scenario Builder (dilewati)"
  fi

  # Offensive Tools
  if [ "$OFFENSIVE_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} Offensive Tools  (update)"
  elif [ "$INSTALL_OFFENSIVE" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} Offensive Tools  (install baru)"
  else
    echo -e "  ${RED}[-]${NC} Offensive Tools  (dilewati)"
  fi
  
  # NEXUS
  if [ "$NEXUS_FLAG" -eq 1 ]; then
    echo -e "  ${GREEN}[↑]${NC} NEXUS            (update)"
  elif [ "$INSTALL_NEXUS" -eq 1 ]; then
    echo -e "  ${YELLOW}[+]${NC} NEXUS            (install baru)"
  else
    echo -e "  ${RED}[-]${NC} NEXUS            (dilewati)"
  fi

  echo ""
  print_line

  IFS= read -r -p "Lanjut update? (YES): " confirm

  if [ "$confirm" != "YES" ]; then
    echo ""
    echo -e "${RED}[!] Update dibatalkan${NC}"
    sleep 2
    clear
    exit 1
  fi
}

# =========================
# 📥 DOWNLOAD FILES
# =========================
download_files() {
  progress_bar 25 "Preparing update"

  rm -rf "$UPDATE_DIR"
  mkdir -p "$UPDATE_DIR"

  sleep 1

  # Main script — selalu download
  progress_bar 30 "Downloading kecembung"
  curl -fsSL "$SCRIPT_URL" -o "$TMP_MAIN"

  if [ ! -s "$TMP_MAIN" ]; then
    echo ""
    echo -e "${RED}[!] Gagal download kecembung${NC}"
    exit 1
  fi

  # AI Detect
  if [ "$AI_DETECT_FLAG" -eq 1 ] || [ "$INSTALL_AI_DETECT" -eq 1 ]; then
    progress_bar 38 "Downloading ai_detect.py"
    curl -fsSL "$AI_DETECT_URL" -o "$TMP_AI_DETECT"

    if [ ! -s "$TMP_AI_DETECT" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download ai_detect.py${NC}"
      exit 1
    fi
  else
    progress_bar 38 "Skipping ai_detect.py"
    sleep 0.3
  fi

  # AI Train
  if [ "$AI_TRAIN_FLAG" -eq 1 ] || [ "$INSTALL_AI_TRAIN" -eq 1 ]; then
    progress_bar 50 "Downloading ai_train.py"
    curl -fsSL "$AI_TRAIN_URL" -o "$TMP_AI_TRAIN"

    if [ ! -s "$TMP_AI_TRAIN" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download ai_train.py${NC}"
      exit 1
    fi
  else
    progress_bar 50 "Skipping ai_train.py"
    sleep 0.3
  fi

  # AI Chat
  if [ "$AI_CHAT_FLAG" -eq 1 ] || [ "$INSTALL_AI_CHAT" -eq 1 ]; then
    progress_bar 62 "Downloading ai_chat.py"
    curl -fsSL "$AI_CHAT_URL" -o "$TMP_AI_CHAT"

    if [ ! -s "$TMP_AI_CHAT" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download ai_chat.py${NC}"
      exit 1
    fi
  else
    progress_bar 62 "Skipping ai_chat.py"
    sleep 0.3
  fi

  # Scenario Builder
  if [ "$SCENARIO_FLAG" -eq 1 ] || [ "$INSTALL_SCENARIO" -eq 1 ]; then
    progress_bar 74 "Downloading scenario_builder.sh"
    curl -fsSL "$SCENARIO_URL" -o "$TMP_SCENARIO"

    if [ ! -s "$TMP_SCENARIO" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download scenario_builder.sh${NC}"
      exit 1
    fi
  else
    progress_bar 74 "Skipping scenario_builder.sh"
    sleep 0.3
  fi

  # Offensive Tools
  if [ "$OFFENSIVE_FLAG" -eq 1 ] || [ "$INSTALL_OFFENSIVE" -eq 1 ]; then
    progress_bar 82 "Downloading offensive_tools.sh"
    curl -fsSL "$OFFENSIVE_URL" -o "$TMP_OFFENSIVE"

    if [ ! -s "$TMP_OFFENSIVE" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download offensive_tools.sh${NC}"
      exit 1
    fi
  else
    progress_bar 82 "Skipping offensive_tools.sh"
    sleep 0.3
  fi
  
  # NEXUS
  if [ "$NEXUS_FLAG" -eq 1 ] || [ "$INSTALL_NEXUS" -eq 1 ]; then
    progress_bar 86 "Downloading nexus.sh"
    curl -fsSL "$NEXUS_URL" -o "$TMP_NEXUS"

    if [ ! -s "$TMP_NEXUS" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download nexus.sh${NC}"
      exit 1
    fi
  else
    progress_bar 86 "Skipping nexus.sh"
    sleep 0.3
  fi

  sleep 1
}

# =========================
# ⚙️ INSTALL KOMPONEN BARU
# =========================
install_new_components() {

  # Python venv — kalau AI Detect atau AI Train baru diinstall
  NEED_VENV=0
  [ "$INSTALL_AI_DETECT" -eq 1 ] && NEED_VENV=1
  [ "$INSTALL_AI_TRAIN"  -eq 1 ] && NEED_VENV=1

  AI_ENV="$HOME/kecembung-env"

  if [ "$NEED_VENV" -eq 1 ]; then

    progress_bar 84 "Setting up Python venv"

    if [ ! -d "$AI_ENV" ] || \
       [ ! -x "$AI_ENV/bin/python" ] || \
       [ ! -x "$AI_ENV/bin/pip" ]; then

      sudo apt install -y python3 python3-pip python3-venv >/dev/null 2>&1
      python3 -m venv "$AI_ENV"
      "$AI_ENV/bin/pip" install --upgrade pip >/dev/null 2>&1
      "$AI_ENV/bin/pip" install ultralytics opencv-python --no-cache-dir >/dev/null 2>&1

      if [ "$INSTALL_AI_DETECT" -eq 1 ]; then
        "$AI_ENV/bin/pip" install torch torchvision torchaudio \
          --index-url https://download.pytorch.org/whl/cpu >/dev/null 2>&1
      fi

    fi

  fi

  # Ollama — kalau AI Chat baru diinstall
  if [ "$INSTALL_AI_CHAT" -eq 1 ]; then

    progress_bar 86 "Installing Ollama"

    if ! command -v ollama >/dev/null 2>&1; then
      curl -fsSL https://ollama.com/install.sh | sh >/dev/null 2>&1
    fi

    # Update OLLAMA_FLAG karena sekarang sudah terinstall
    OLLAMA_FLAG=1

  fi
  
  # =========================
  # 💀 OFFENSIVE DEPS
  # =========================
  if [ "$INSTALL_OFFENSIVE" -eq 1 ]; then

    progress_bar 87 "Installing Offensive dependencies"

    # Install semua deps Ghost Protocol v2.1.0
    sudo apt install -y nmap masscan aircrack-ng exploitdb hcxtools reaver hostapd dnsmasq bluez inotify-tools tor knockd fail2ban pandoc wkhtmltopdf >/dev/null 2>&1

    if [ $? -eq 0 ]; then
      ok "Offensive dependencies installed"
    else
      warn "Some offensive dependencies failed"
      warn "Run manually: apt install nmap masscan aircrack-ng exploitdb hcxtools reaver hostapd dnsmasq bluez inotify-tools tor knockd fail2ban pandoc wkhtmltopdf"
    fi
  fi
  
  # =========================
  # 🔗 NEXUS DEPS
  # =========================
  if [ "$INSTALL_NEXUS" -eq 1 ]; then
    progress_bar 89 "Installing NEXUS dependencies"
    sudo apt install -y zerotier-one jq curl git >/dev/null 2>&1
    sudo systemctl enable zerotier-one >/dev/null 2>&1
  fi
}

# =========================
# 🧹 CLEAN OLD FILES
# =========================
cleanup_old() {
  progress_bar 88 "Cleaning old files"

  [ "$AI_DETECT_FLAG"  -eq 1 ] && rm -f "$AI_DETECT_FILE"
  [ "$AI_TRAIN_FLAG"   -eq 1 ] && rm -f "$AI_TRAIN_FILE"
  [ "$AI_CHAT_FLAG"    -eq 1 ] && rm -f "$AI_CHAT_FILE"
  [ "$SCENARIO_FLAG"   -eq 1 ] && rm -f "$SCENARIO_FILE"
  [ "$OFFENSIVE_FLAG"  -eq 1 ] && rm -f "$OFFENSIVE_FILE"
  [ "$NEXUS_FLAG"      -eq 1 ] && rm -f "$NEXUS_FILE"

  sleep 1
}

# =========================
# 📦 INSTALL UPDATE
# =========================
install_update() {
  progress_bar 92 "Installing update"

  mkdir -p "$AI_DIR"
  mkdir -p "$SCENARIO_DIR"
  mkdir -p "$OFFENSIVE_DIR"
  mkdir -p "$NEXUS_DIR"

  # Main script — selalu install
  sudo mv "$TMP_MAIN" "$MAIN_SCRIPT"
  sudo chmod +x "$MAIN_SCRIPT"

  # bung symlink pastikan masih ada
  if [ ! -f /usr/local/bin/bung ]; then
    cat > /tmp/bung <<'BUNGSCRIPT'
#!/bin/bash
exec /usr/local/bin/kecembung "$@"
BUNGSCRIPT
    sudo mv /tmp/bung /usr/local/bin/bung
    sudo chmod +x /usr/local/bin/bung
  fi

  # AI Detect
  if [ "$AI_DETECT_FLAG" -eq 1 ] || [ "$INSTALL_AI_DETECT" -eq 1 ]; then
    [ -f "$TMP_AI_DETECT" ] && mv "$TMP_AI_DETECT" "$AI_DETECT_FILE"
  fi

  # AI Train
  if [ "$AI_TRAIN_FLAG" -eq 1 ] || [ "$INSTALL_AI_TRAIN" -eq 1 ]; then
    [ -f "$TMP_AI_TRAIN" ] && mv "$TMP_AI_TRAIN" "$AI_TRAIN_FILE"
  fi

  # AI Chat
  if [ "$AI_CHAT_FLAG" -eq 1 ] || [ "$INSTALL_AI_CHAT" -eq 1 ]; then
    [ -f "$TMP_AI_CHAT" ] && mv "$TMP_AI_CHAT" "$AI_CHAT_FILE"
  fi

  # Scenario Builder
  if [ "$SCENARIO_FLAG" -eq 1 ] || [ "$INSTALL_SCENARIO" -eq 1 ]; then
    [ -f "$TMP_SCENARIO" ] && mv "$TMP_SCENARIO" "$SCENARIO_FILE"
    chmod +x "$SCENARIO_FILE" 2>/dev/null
  fi

  # Offensive Tools
  if [ "$OFFENSIVE_FLAG" -eq 1 ] || [ "$INSTALL_OFFENSIVE" -eq 1 ]; then
    [ -f "$TMP_OFFENSIVE" ] && mv "$TMP_OFFENSIVE" "$OFFENSIVE_FILE"
    chmod +x "$OFFENSIVE_FILE" 2>/dev/null
  fi
  
  # NEXUS
  if [ "$NEXUS_FLAG" -eq 1 ] || [ "$INSTALL_NEXUS" -eq 1 ]; then
    [ -f "$TMP_NEXUS" ] && mv "$TMP_NEXUS" "$NEXUS_FILE"
    chmod +x "$NEXUS_FILE" 2>/dev/null
  fi

  sleep 1
}

# =========================
# 💾 UPDATE MODE FLAG
# =========================
update_mode_flag() {

  # Update flag kalau ada komponen baru yang berhasil diinstall
  [ "$INSTALL_AI_DETECT"  -eq 1 ] && AI_DETECT_FLAG=1
  [ "$INSTALL_AI_TRAIN"   -eq 1 ] && AI_TRAIN_FLAG=1
  [ "$INSTALL_AI_CHAT"    -eq 1 ] && AI_CHAT_FLAG=1
  [ "$INSTALL_SCENARIO"   -eq 1 ] && SCENARIO_FLAG=1
  [ "$INSTALL_OFFENSIVE"  -eq 1 ] && OFFENSIVE_FLAG=1
  [ "$INSTALL_NEXUS"       -eq 1 ] && NEXUS_FLAG=1

  cat > "$MODE_FILE" <<EOF
AI_DETECT=$AI_DETECT_FLAG
AI_TRAIN=$AI_TRAIN_FLAG
AI_CHAT=$AI_CHAT_FLAG
SCENARIO=$SCENARIO_FLAG
OLLAMA=$OLLAMA_FLAG
OFFENSIVE=$OFFENSIVE_FLAG
NEXUS=$NEXUS_FLAG
EOF

  chmod 600 "$MODE_FILE"
}

# =========================
# ✅ FINALIZE
# =========================
finish_update() {
  progress_bar 100 "KECEMBUNG updated successfully"

  rm -rf "$UPDATE_DIR"

  echo ""
  print_line
  echo -e "${GREEN}[✔] KECEMBUNG BERHASIL DIUPDATE${NC}"
  print_line

  echo ""
  echo -e "${CYAN}Komponen aktif sekarang:${NC}"
  echo ""
  echo -e "  ${GREEN}[✔]${NC} kecembung (main script)"
  [ "$AI_DETECT_FLAG"  -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} AI Detect"
  [ "$AI_TRAIN_FLAG"   -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} AI Train"
  [ "$AI_CHAT_FLAG"    -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} AI Chat"
  [ "$SCENARIO_FLAG"   -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} Scenario Builder"
  [ "$OFFENSIVE_FLAG"  -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} Offensive Tools"
  [ "$NEXUS_FLAG"      -eq 1 ] && echo -e "  ${GREEN}[✔]${NC} NEXUS"
  echo ""

  sleep 2
  clear

  exec /usr/local/bin/kecembung
}

# =========================
# 🚀 MAIN
# =========================
print_title

check_internet
validate_server
check_missing_components
confirm_update
download_files
install_new_components
cleanup_old
install_update
update_mode_flag
finish_update
