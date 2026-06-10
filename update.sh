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
# 📋 SOURCE MODE FLAGS
# =========================
MODE_FILE="$HOME/.kecembung_mode"

AI_DETECT_FLAG=0
AI_TRAIN_FLAG=0
AI_CHAT_FLAG=0
SCENARIO_FLAG=0
OLLAMA_FLAG=0

if [ -f "$MODE_FILE" ]; then
  source "$MODE_FILE"
  AI_DETECT_FLAG="${AI_DETECT:-0}"
  AI_TRAIN_FLAG="${AI_TRAIN:-0}"
  AI_CHAT_FLAG="${AI_CHAT:-0}"
  SCENARIO_FLAG="${SCENARIO:-0}"
  OLLAMA_FLAG="${OLLAMA:-0}"
fi

# =========================
# 📁 KECEMBUNG PATH
# =========================
BASE_DIR="$HOME/.kecembung"

AI_DIR="$BASE_DIR/ai"
SCENARIO_DIR="$BASE_DIR/scenarios"
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

SCENARIO_URL="$REPO_URL/kecembung_/scenario/scenario_builder.sh"

# =========================
# 📂 TARGET FILES
# =========================
MAIN_SCRIPT="$HOME/kecembung"

AI_DETECT_FILE="$AI_DIR/ai_detect.py"
AI_TRAIN_FILE="$AI_DIR/ai_train.py"

SCENARIO_FILE="$SCENARIO_DIR/scenario_builder.sh"

# =========================
# 📥 TEMP FILES
# =========================
TMP_MAIN="$UPDATE_DIR/kecembung"

TMP_AI_DETECT="$UPDATE_DIR/ai_detect.py"
TMP_AI_TRAIN="$UPDATE_DIR/ai_train.py"

TMP_SCENARIO="$UPDATE_DIR/scenario_builder.sh"

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
  echo -e "${CYAN}Komponen yang akan diupdate:${NC}"
  echo "  [✔] kecembung (main script)"
  echo "  [✔] scenario_builder.sh"

  if [ "$AI_DETECT_FLAG" -eq 1 ]; then
    echo "  [✔] ai_detect.py"
  else
    echo "  [-] ai_detect.py (dilewati, AI_DETECT=0)"
  fi

  if [ "$AI_TRAIN_FLAG" -eq 1 ]; then
    echo "  [✔] ai_train.py"
  else
    echo "  [-] ai_train.py (dilewati, AI_TRAIN=0)"
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
  progress_bar 35 "Downloading kecembung"
  curl -fsSL "$SCRIPT_URL" -o "$TMP_MAIN"

  if [ ! -s "$TMP_MAIN" ]; then
    echo ""
    echo -e "${RED}[!] Gagal download kecembung${NC}"
    exit 1
  fi

  # AI detect — hanya kalau flag aktif
  if [ "$AI_DETECT_FLAG" -eq 1 ]; then
    progress_bar 50 "Downloading ai_detect.py"
    curl -fsSL "$AI_DETECT_URL" -o "$TMP_AI_DETECT"

    if [ ! -s "$TMP_AI_DETECT" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download ai_detect.py${NC}"
      exit 1
    fi
  else
    progress_bar 50 "Skipping ai_detect.py (flag off)"
    sleep 0.5
  fi

  # AI train — hanya kalau flag aktif
  if [ "$AI_TRAIN_FLAG" -eq 1 ]; then
    progress_bar 65 "Downloading ai_train.py"
    curl -fsSL "$AI_TRAIN_URL" -o "$TMP_AI_TRAIN"

    if [ ! -s "$TMP_AI_TRAIN" ]; then
      echo ""
      echo -e "${RED}[!] Gagal download ai_train.py${NC}"
      exit 1
    fi
  else
    progress_bar 65 "Skipping ai_train.py (flag off)"
    sleep 0.5
  fi

  # Scenario builder — selalu download
  progress_bar 75 "Downloading scenario_builder.sh"
  curl -fsSL "$SCENARIO_URL" -o "$TMP_SCENARIO"

  if [ ! -s "$TMP_SCENARIO" ]; then
    echo ""
    echo -e "${RED}[!] Gagal download scenario_builder.sh${NC}"
    exit 1
  fi

  sleep 1
}

# =========================
# 🧹 CLEAN OLD FILES
# =========================
cleanup_old() {
  progress_bar 85 "Cleaning old files"

  rm -f "$MAIN_SCRIPT"
  rm -f "$SCENARIO_FILE"

  [ "$AI_DETECT_FLAG" -eq 1 ] && rm -f "$AI_DETECT_FILE"
  [ "$AI_TRAIN_FLAG"  -eq 1 ] && rm -f "$AI_TRAIN_FILE"

  sleep 1
}

# =========================
# 📦 INSTALL UPDATE
# =========================
install_update() {
  progress_bar 90 "Installing update"

  mkdir -p "$AI_DIR"
  mkdir -p "$SCENARIO_DIR"

  mv "$TMP_MAIN" "$MAIN_SCRIPT"
  chmod +x "$MAIN_SCRIPT"

  mv "$TMP_SCENARIO" "$SCENARIO_FILE"
  chmod +x "$SCENARIO_FILE"

  if [ "$AI_DETECT_FLAG" -eq 1 ] && [ -f "$TMP_AI_DETECT" ]; then
    mv "$TMP_AI_DETECT" "$AI_DETECT_FILE"
  fi

  if [ "$AI_TRAIN_FLAG" -eq 1 ] && [ -f "$TMP_AI_TRAIN" ]; then
    mv "$TMP_AI_TRAIN" "$AI_TRAIN_FILE"
  fi

  sleep 1
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

  sleep 2
  clear

  exec 0
}

# =========================
# 🚀 MAIN
# =========================
print_title

check_internet
validate_server
confirm_update
download_files
cleanup_old
install_update
finish_update
