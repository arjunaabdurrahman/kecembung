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
# 📁 SCENARIO DIR
# =========================
SCENARIO_DIR="$HOME/kecembung_scenarios"
mkdir -p "$SCENARIO_DIR"

# =========================
# 📦 LABEL (USER VIEW)
# =========================

# =========================
# 📂 CATEGORY
# =========================

categories=(
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

labels=(
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

# =========================
# 📦 COMMAND (SYSTEM)
# =========================
commands=(
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
# 🧠 AI SCENARIO PROMPT
# =========================

AI_SCENARIO_PROMPT="
Kamu adalah generator KECEMBUNG scenario.

Tugas:
- ubah request user menjadi daftar command KECEMBUNG
- output HANYA command
- satu command per baris
- jangan jelaskan apapun
- jangan gunakan command selain whitelist

Whitelist command:

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
"

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
  echo "3. AI Scenario"
  echo "4. Delete Scenario"
  echo "5. Back"
  echo -e "${CYAN}=========================${NC}"

  read -p "Select mode: " mode

  case $mode in

    # =========================
    # ✍️ CUSTOM MODE
    # =========================
    1)
      echo -e "${CYAN}=========================${NC}"
      read -p "👉 Nama scenario (contoh: tcp_scan_home): " scen_name

      if [ -z "$scen_name" ]; then
        echo -e "${RED}[!] Nama tidak boleh kosong${NC}"
        continue
      fi

      if [[ "$scen_name" =~ [[:space:]] ]]; then
        echo -e "${RED}[!] Tidak boleh pakai spasi, gunakan _${NC}"
        continue
      fi

      FILE="$SCENARIO_DIR/${scen_name}.sh"
      > "$FILE"

      echo -e "${YELLOW}[~] CUSTOM MODE${NC}"
      echo "Type command (cmd_*), type 'done' to finish"

      while true; do
        read -p "cmd> " cmd

        if [ "$cmd" = "done" ]; then
          break
        fi

        if declare -f "$cmd" > /dev/null; then
          echo "$cmd" >> "$FILE"
          echo -e "${GREEN}[✔] added: ${labels[$cmd]}${NC}" 2>/dev/null
          echo -e "${GREEN}[✔] added: $cmd${NC}"
        else
          echo -e "${RED}[X] unknown command: $cmd${NC}"
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
    	  continue
      fi

      if [[ ! "$scenario_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
    	  echo "[!] Nama hanya boleh huruf, angka, dan underscore (_)"
    	  continue
      fi

      if [[ "$scenario_name" =~ [[:space:]] ]]; then
        echo -e "${RED}[!] Tidak boleh pakai spasi, gunakan _${NC}"
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

      echo -e "${CYAN}=========================${NC}"
      echo "Select numbers (example: 0 3 5), type 'done'"

      while true; do
        read -p "select> " input

        if [ "$input" = "done" ]; then
          break
        fi

        for num in $input; do
          cmd="${commands[$num]}"
          label="${labels[$num]}"

          if [ -n "$cmd" ]; then
            if grep -qx "$cmd" "$FILE" 2>/dev/null; then
              echo -e "${YELLOW}[!] already added: $label${NC}"
            else
              echo "$cmd" >> "$FILE"
              echo -e "${GREEN}[✔] added: $label${NC}"
            fi
            echo -e "${GREEN}[✔] added: $label${NC}"
          else
            echo -e "${RED}[X] invalid index: $num${NC}"
          fi
        done
      done

      echo -e "${CYAN}[✔] saved: $FILE${NC}"
      read -p "ENTER..."
      ;;
    
    3)

      if ! command -v ollama >/dev/null 2>&1; then
        echo "[!] Ollama belum terinstall"
        read -p "ENTER..."
        continue
      fi

      echo -e "${CYAN}=========================${NC}"
      echo -e "${GREEN}      AI SCENARIO${NC}"
      echo -e "${CYAN}=========================${NC}"

      read -p "Nama scenario: " scenario_name

      if [ -z "$scenario_name" ]; then
        echo "[!] Nama tidak boleh kosong"
        continue
      fi

      FILE="$SCENARIO_DIR/${scenario_name}.sh"

      echo ""
      read -p "Request AI: " user_prompt

      [ -z "$user_prompt" ] && continue

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
      read -p "Save scenario? (YES): " confirm

      [ "$confirm" != "YES" ] && continue

      > "$FILE"

      while IFS= read -r line; do

        line=$(echo "$line" | xargs)

        [[ ! "$line" =~ ^cmd_ ]] && continue

        echo "$line" >> "$FILE"

      done <<< "$response"

      echo ""
      echo "[✔] Scenario saved: $FILE"

      read -p "ENTER..."
      ;;
    
    4)
      echo -e "${CYAN}=========================${NC}"
      echo -e "${RED}   DELETE SCENARIO${NC}"
      echo -e "${CYAN}=========================${NC}"

      files=("$SCENARIO_DIR"/*.sh)

      if [ ! -e "${files[0]}" ]; then
        echo -e "${RED}[!] Tidak ada scenario${NC}"
        read -p "ENTER untuk kembali..."
        continue
      fi

      for i in "${!files[@]}"; do
        echo -e "${YELLOW}$i${NC}. $(basename "${files[$i]}")"
      done

      echo -e "${CYAN}=========================${NC}"
      read -p "👉 Pilih nomor scenario: " del_index

      target="${files[$del_index]}"

      if [ -z "$target" ] || [ ! -f "$target" ]; then
        echo -e "${RED}[!] Pilihan tidak valid${NC}"
        read -p "ENTER untuk kembali..."
      fi

      echo -e "${RED}[!] Akan menghapus: $(basename "$target")${NC}"
      read -p "Ketik YES untuk konfirmasi: " confirm

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
    5)
      break
      ;;

    *)
      echo -e "${RED}[!] invalid option${NC}"
      sleep 1
      ;;
  esac

done
