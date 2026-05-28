#!/bin/bash

# =========================
# 🚀 NETTOOLS UPDATE ENGINE
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
# 📁 NETTOOLS PATH
# =========================
BASE_DIR="$HOME/.nettool"

AI_DIR="$BASE_DIR/ai"
SCENARIO_DIR="$BASE_DIR/scenarios"

UPDATE_DIR="$BASE_DIR/update"

mkdir -p "$UPDATE_DIR"

# =========================
# 🌐 UPDATE CONFIG
# =========================
CURRENT_VERSION="2.5.0"

REPO_URL="https://raw.githubusercontent.com/arjunaabdurrahman/nettool/main"

VERSION_URL="$REPO_URL/version.txt"
CHANGELOG_URL="$REPO_URL/changelog.txt"

SCRIPT_URL="$REPO_URL/normal_nettool"

AI_DETECT_URL="$REPO_URL/nettools/ai/ai_detect.py"
AI_TRAIN_URL="$REPO_URL/nettools/ai/ai_train.py"

SCENARIO_URL="$REPO_URL/nettools/scenario/scenario_builder.sh"

INSTALLER_URL="$REPO_URL/install.sh"

# =========================
# 📂 TARGET FILES
# =========================
MAIN_SCRIPT="$HOME/normal_nettool"

AI_DETECT_FILE="$AI_DIR/ai_detect.py"
AI_TRAIN_FILE="$AI_DIR/ai_train.py"

SCENARIO_FILE="$SCENARIO_DIR/scenario_builder.sh"

# =========================
# 📥 TEMP FILES
# =========================
TMP_MAIN="$UPDATE_DIR/normal_nettool"

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
    echo -e "${GREEN}        NETTOOLS UPDATE${NC}"
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
        echo -e "${RED}[!] Update server invalid (HTTP $HTTP_STATUS)${NC}"
        exit 1
    fi

    progress_bar 20 "Server validated"
    sleep 1
}

# =========================
# 🧠 GET MODEL NAME
# =========================
get_model_name() {

    if command -v ollama >/dev/null 2>&1; then

        MODEL_NAME=$(ollama list 2>/dev/null | \
        awk 'NR==2 {print $1}')

        [ -z "$MODEL_NAME" ] && MODEL_NAME="default"

    else
        MODEL_NAME="default"
    fi
}

# =========================
# ⚠️ USER VALIDATION
# =========================
confirm_update() {

    echo ""
    print_line

    echo -e "${YELLOW}Version sekarang : ${NC}$CURRENT_VERSION"

    LATEST_VERSION=$(curl -s "$VERSION_URL" | tr -d '\n\r')

    echo -e "${GREEN}Version terbaru  : ${NC}$LATEST_VERSION"

    print_line

    echo ""
    echo -e "${BLUE}Perubahan terbaru:${NC}"
    echo ""

    curl -s "$CHANGELOG_URL"

    echo ""
    print_line

    read -p "Lanjut update? (YES): " confirm

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

    progress_bar 35 "Downloading normal_nettool"

    curl -fsSL "$SCRIPT_URL" \
    -o "$TMP_MAIN"

    progress_bar 50 "Downloading ai_detect.py"

    curl -fsSL "$AI_DETECT_URL" \
    -o "$TMP_AI_DETECT"

    progress_bar 65 "Downloading ai_train.py"

    curl -fsSL "$AI_TRAIN_URL" \
    -o "$TMP_AI_TRAIN"

    progress_bar 75 "Downloading scenario_builder"

    curl -fsSL "$SCENARIO_URL" \
    -o "$TMP_SCENARIO"

    sleep 1
}

# =========================
# 🔍 VALIDATE FILES
# =========================
validate_files() {

    progress_bar 80 "Validating files"

    if [ ! -s "$TMP_MAIN" ]; then
        echo ""
        echo -e "${RED}[!] normal_nettool corrupt${NC}"
        exit 1
    fi

    if [ ! -s "$TMP_AI_DETECT" ]; then
        echo ""
        echo -e "${RED}[!] ai_detect.py corrupt${NC}"
        exit 1
    fi

    if [ ! -s "$TMP_AI_TRAIN" ]; then
        echo ""
        echo -e "${RED}[!] ai_train.py corrupt${NC}"
        exit 1
    fi

    if [ ! -s "$TMP_SCENARIO" ]; then
        echo ""
        echo -e "${RED}[!] scenario_builder corrupt${NC}"
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

    rm -f "$AI_DETECT_FILE"
    rm -f "$AI_TRAIN_FILE"

    rm -f "$SCENARIO_FILE"

    sleep 1
}

# =========================
# 📦 INSTALL UPDATE
# =========================
install_update() {

    progress_bar 90 "Updating [$MODEL_NAME] NETTOOLS"

    mkdir -p "$AI_DIR"
    mkdir -p "$SCENARIO_DIR"

    mv "$TMP_MAIN" \
    "$MAIN_SCRIPT"

    mv "$TMP_AI_DETECT" \
    "$AI_DETECT_FILE"

    mv "$TMP_AI_TRAIN" \
    "$AI_TRAIN_FILE"

    mv "$TMP_SCENARIO" \
    "$SCENARIO_FILE"

    chmod +x "$MAIN_SCRIPT"
    chmod +x "$SCENARIO_FILE"

    sleep 1
}

# =========================
# ✅ FINALIZE
# =========================
finish_update() {

    progress_bar 100 "NETTOOLS updated successfully"

    rm -rf "$UPDATE_DIR"

    echo ""
    echo -e "${GREEN}[✔] NETTOOLS BERHASIL DIUPDATE${NC}"

    sleep 3

    clear

    exec "$MAIN_SCRIPT"
}

# =========================
# 🚀 MAIN
# =========================
print_title

get_model_name

check_internet

validate_server

confirm_update

download_files

validate_files

cleanup_old

install_update

finish_update
