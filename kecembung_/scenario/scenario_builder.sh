#!/bin/bash

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
# 📁 SCENARIO DIR
# =========================
SCENARIO_DIR="$HOME/.kecembung/scenarios"
mkdir -p "$SCENARIO_DIR"

# =========================
# 📂 CATEGORY + LABEL + COMMAND (FULL LIST)
# =========================

all_categories=(
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"
"IP TOOLS"

"TCP TOOLS"
"TCP TOOLS"
"TCP TOOLS"
"TCP TOOLS"
"TCP TOOLS"
"TCP TOOLS"

"AI TOOLS"
"AI TOOLS"
"AI TOOLS"
"AI TOOLS"
"AI TOOLS"
"AI TOOLS"
"AI TOOLS"

"STORAGE"
"STORAGE"
"STORAGE"
"STORAGE"

"USB TOOLS"
"USB TOOLS"
"USB TOOLS"
"USB TOOLS"
"USB TOOLS"
)

all_labels=(
"Lihat IP"
"Scan Jaringan"
"Ping IP"
"Set IP Manual"
"Routing Info"
"DNS Check"
"Internet Check"
"Scan SSH"
"SSH Connect"
"Reset IP"

"TCP Scan Port"
"TCP Service Detection"
"TCP Range Scan"
"TCP Specific Port"
"TCP Local Ports"
"TCP Banner Grab"

"AI Webcam All"
"AI Webcam Person"
"AI RTSP"
"AI Image Detection"
"AI Video Detection"
"AI Train Model"
"AI Run Model"

"Storage Local Mode"
"Storage USB Mode"
"Install Package"
"Save Log"

"USB Detect"
"USB Select"
"USB Workspace"
"USB Read"
"USB Delete"
)

all_commands=(
cmd_lihat_ip
cmd_scan_jaringan
cmd_ping_ip
cmd_set_ip_manual
cmd_routing
cmd_dns_check
cmd_internet_check
cmd_scan_ssh
cmd_ssh_connect
cmd_reset_ip

cmd_tcp_scan_port
cmd_tcp_service_detection
cmd_tcp_range_scan
cmd_tcp_specific_port
cmd_tcp_local_ports
cmd_tcp_banner_grab

cmd_ai_webcam_all
cmd_ai_webcam_person
cmd_ai_rtsp
cmd_ai_image
cmd_ai_video
cmd_ai_train
cmd_ai_run

cmd_storage_local
cmd_storage_usb
cmd_storage_install
cmd_storage_save_log

cmd_usb_detect
cmd_usb_select
cmd_usb_workspace
cmd_usb_read
cmd_usb_delete
)

# =========================
# 🔧 BUILD ACTIVE LIST (filter AI kalau flag off)
# =========================

categories=()
labels=()
commands=()

for i in "${!all_commands[@]}"; do
  cat="${all_categories[$i]}"
  cmd="${all_commands[$i]}"

  # Filter AI commands berdasarkan flag
  if [ "$cat" = "AI TOOLS" ]; then
    # cmd_ai_train → butuh AI_TRAIN_FLAG
    if [ "$cmd" = "cmd_ai_train" ] && [ "$AI_TRAIN_FLAG" -ne 1 ]; then
      continue
    fi
    # cmd_ai_* lainnya → butuh AI_DETECT_FLAG
    if [ "$cmd" != "cmd_ai_train" ] && [ "$AI_DETECT_FLAG" -ne 1 ]; then
      continue
    fi
  fi

  categories+=("$cat")
  labels+=("${all_labels[$i]}")
  commands+=("$cmd")
done

# =========================
# 🧠 AI SCENARIO PROMPT (whitelist dinamis)
# =========================

build_ai_prompt() {
  local whitelist=""

  for cmd in "${commands[@]}"; do
    whitelist="$whitelist
$cmd"
  done

  echo "
Kamu adalah generator KECEMBUNG scenario.

Tugas:
- ubah request user menjadi daftar command KECEMBUNG
- output HANYA command
- satu command per baris
- jangan jelaskan apapun
- jangan gunakan command selain whitelist

Whitelist command:
$whitelist
"
}

# =========================
# 🚀 MAIN LOOP
# =========================
while true; do

  clear
  echo -e "${CYAN}=========================${NC}"
  echo -e "${GREEN}   SCENARIO BUILDER${NC}"
  echo -e "${CYAN}=========================${NC}"
  echo "1. Custom (manual input)"
  echo "2. From Kecembung (select list)"

  # Tampilkan AI Scenario hanya kalau Ollama aktif
  if [ "$OLLAMA_FLAG" -eq 1 ]; then
    echo "3. AI Scenario"
    echo "4. Delete Scenario"
    echo "5. Back"
  else
    echo "3. Delete Scenario"
    echo "4. Back"
  fi

  echo -e "${CYAN}=========================${NC}"

  read -p "Select mode: " mode

  # Remap opsi kalau OLLAMA_FLAG=0 (tidak ada menu AI Scenario)
  if [ "$OLLAMA_FLAG" -ne 1 ]; then
    case $mode in
      3) mode="__delete" ;;
      4) mode="__back"   ;;
    esac
  else
    case $mode in
      4) mode="__delete" ;;
      5) mode="__back"   ;;
    esac
  fi

  case $mode in

    # =========================
    # ✍️ CUSTOM MODE
    # =========================
    1)
      echo -e "${CYAN}=========================${NC}"
      IFS= read -r -p "👉 Nama scenario (tanpa spasi, pakai _): " scen_name

      scen_name=$(echo "$scen_name" | xargs)

      if [ -z "$scen_name" ]; then
        echo -e "${RED}[!] Nama tidak boleh kosong${NC}"
        read -p "ENTER..."
        continue
      fi

      if [[ ! "$scen_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${RED}[!] Nama hanya boleh huruf, angka, dan underscore (_)${NC}"
        read -p "ENTER..."
        continue
      fi

      FILE="$SCENARIO_DIR/${scen_name}.sh"
      > "$FILE"

      echo -e "${YELLOW}[~] CUSTOM MODE${NC}"
      echo "Ketik command (cmd_*), ketik 'done' untuk selesai"
      echo ""
      echo "Command tersedia:"

      last_category=""
      for i in "${!commands[@]}"; do
        cur_cat="${categories[$i]}"
        if [ "$cur_cat" != "$last_category" ]; then
          echo ""
          echo -e "${CYAN}[$cur_cat]${NC}"
          last_category="$cur_cat"
        fi
        echo -e "  ${YELLOW}${commands[$i]}${NC} → ${labels[$i]}"
      done

      echo ""

      while true; do
        IFS= read -r -p "cmd> " cmd

        if [ "$cmd" = "done" ]; then
          break
        fi

        [ -z "$cmd" ] && continue

        # Validasi command ada di active list
        valid=0
        for c in "${commands[@]}"; do
          [ "$c" = "$cmd" ] && valid=1 && break
        done

        if [ "$valid" -eq 1 ]; then
          echo "$cmd" >> "$FILE"
          echo -e "${GREEN}[✔] added: $cmd${NC}"
        else
          echo -e "${RED}[X] unknown/disabled command: $cmd${NC}"
        fi
      done

      echo -e "${CYAN}[✔] saved: $FILE${NC}"
      read -p "ENTER..."
      ;;

    # =========================
    # 📦 FROM KECEMBUNG MODE
    # =========================
    2)
      echo -e "${CYAN}=========================${NC}"
      IFS= read -r -p "👉 Nama scenario (tanpa spasi, pakai _): " scenario_name

      scenario_name=$(echo "$scenario_name" | xargs)

      if [ -z "$scenario_name" ]; then
        echo "[!] Nama tidak boleh kosong"
        read -p "ENTER..."
        continue
      fi

      if [[ ! "$scenario_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "[!] Nama hanya boleh huruf, angka, dan underscore (_)"
        read -p "ENTER..."
        continue
      fi

      FILE="$SCENARIO_DIR/${scenario_name}.sh"
      > "$FILE"

      echo -e "${CYAN}=========================${NC}"
      echo -e "${GREEN} KECEMBUNG COMMAND LIST${NC}"
      echo -e "${CYAN}=========================${NC}"

      last_category=""

      for i in "${!commands[@]}"; do
        current_category="${categories[$i]}"

        if [ "$current_category" != "$last_category" ]; then
          echo ""
          echo -e "${CYAN}[$current_category]${NC}"
          last_category="$current_category"
        fi

        echo -e "${YELLOW}$i${NC}. ${labels[$i]}"
      done

      echo ""
      echo -e "${CYAN}=========================${NC}"
      echo "Pilih nomor (contoh: 0 3 5), ketik 'done' untuk selesai"

      while true; do
        IFS= read -r -p "select> " input

        if [ "$input" = "done" ]; then
          break
        fi

        [ -z "$input" ] && continue

        for num in $input; do
          if ! [[ "$num" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}[X] bukan angka: $num${NC}"
            continue
          fi

          cmd="${commands[$num]}"
          label="${labels[$num]}"

          if [ -n "$cmd" ]; then
            if grep -qx "$cmd" "$FILE" 2>/dev/null; then
              echo -e "${YELLOW}[!] already added: $label${NC}"
            else
              echo "$cmd" >> "$FILE"
              echo -e "${GREEN}[✔] added: $label${NC}"
            fi
          else
            echo -e "${RED}[X] invalid index: $num${NC}"
          fi
        done
      done

      echo -e "${CYAN}[✔] saved: $FILE${NC}"
      read -p "ENTER..."
      ;;

    # =========================
    # 🤖 AI SCENARIO (hanya kalau OLLAMA_FLAG=1)
    # =========================
    3)
      # Fallback safety — seharusnya tidak tercapai kalau OLLAMA_FLAG=0
      if [ "$OLLAMA_FLAG" -ne 1 ]; then
        echo -e "${RED}[!] invalid option${NC}"
        sleep 1
        continue
      fi

      if ! command -v ollama >/dev/null 2>&1; then
        echo "[!] Ollama belum terinstall"
        read -p "ENTER..."
        continue
      fi

      echo -e "${CYAN}=========================${NC}"
      echo -e "${GREEN}      AI SCENARIO${NC}"
      echo -e "${CYAN}=========================${NC}"

      IFS= read -r -p "Nama scenario: " scenario_name

      scenario_name=$(echo "$scenario_name" | xargs)

      if [ -z "$scenario_name" ]; then
        echo "[!] Nama tidak boleh kosong"
        read -p "ENTER..."
        continue
      fi

      if [[ ! "$scenario_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo "[!] Nama hanya boleh huruf, angka, dan underscore (_)"
        read -p "ENTER..."
        continue
      fi

      FILE="$SCENARIO_DIR/${scenario_name}.sh"

      echo ""
      IFS= read -r -p "Request AI: " user_prompt

      [ -z "$user_prompt" ] && continue

      AI_SCENARIO_PROMPT=$(build_ai_prompt)

      FULL_PROMPT="$AI_SCENARIO_PROMPT

USER REQUEST:
$user_prompt

OUTPUT:
"

      echo ""
      echo "[~] AI generating scenario..."
      echo ""

      response=$(printf "%s" "$FULL_PROMPT" | ollama run phi3:mini 2>/dev/null)

      if [ -z "$response" ]; then
        echo "[!] AI gagal generate"
        read -p "ENTER..."
        continue
      fi

      echo ""
      echo -e "${CYAN}Generated Scenario:${NC}"
      echo ""
      echo "$response"
      echo ""

      IFS= read -r -p "Save scenario? (YES): " confirm

      [ "$confirm" != "YES" ] && continue

      > "$FILE"

      while IFS= read -r line; do
        line=$(echo "$line" | xargs)

        [[ ! "$line" =~ ^cmd_ ]] && continue

        # Validasi hanya command di active list yang disimpan
        valid=0
        for c in "${commands[@]}"; do
          [ "$c" = "$line" ] && valid=1 && break
        done

        if [ "$valid" -eq 1 ]; then
          echo "$line" >> "$FILE"
        else
          echo -e "${YELLOW}[!] skipped (disabled/unknown): $line${NC}"
        fi

      done <<< "$response"

      echo ""
      echo "[✔] Scenario saved: $FILE"
      read -p "ENTER..."
      ;;

    # =========================
    # 🗑️ DELETE SCENARIO
    # =========================
    __delete)
      echo -e "${CYAN}=========================${NC}"
      echo -e "${RED}   DELETE SCENARIO${NC}"
      echo -e "${CYAN}=========================${NC}"

      shopt -s nullglob
      files=("$SCENARIO_DIR"/*.sh)
      shopt -u nullglob

      if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}[!] Tidak ada scenario${NC}"
        read -p "ENTER untuk kembali..."
        continue
      fi

      for i in "${!files[@]}"; do
        echo -e "${YELLOW}$i${NC}. $(basename "${files[$i]}")"
      done

      echo -e "${CYAN}=========================${NC}"
      IFS= read -r -p "👉 Pilih nomor scenario: " del_index

      if ! [[ "$del_index" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] Bukan angka${NC}"
        read -p "ENTER untuk kembali..."
        continue
      fi

      target="${files[$del_index]}"

      if [ -z "$target" ] || [ ! -f "$target" ]; then
        echo -e "${RED}[!] Pilihan tidak valid${NC}"
        read -p "ENTER untuk kembali..."
        continue
      fi

      echo -e "${RED}[!] Akan menghapus: $(basename "$target")${NC}"
      IFS= read -r -p "Ketik YES untuk konfirmasi: " confirm

      if [ "$confirm" = "YES" ]; then
        rm -f "$target"
        echo -e "${GREEN}[✔] Scenario berhasil dihapus${NC}"
      else
        echo -e "${YELLOW}[x] Dibatalkan${NC}"
      fi

      read -p "ENTER untuk kembali..."
      ;;

    # =========================
    # 🔙 BACK
    # =========================
    __back)
      break
      ;;

    *)
      echo -e "${RED}[!] invalid option${NC}"
      sleep 1
      ;;
  esac

done
