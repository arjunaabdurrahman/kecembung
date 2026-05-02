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
SCENARIO_DIR="$HOME/nettools_scenarios"
mkdir -p "$SCENARIO_DIR"

# =========================
# 📦 LABEL (USER VIEW)
# =========================
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
# 🚀 MAIN LOOP
# =========================
while true; do

  clear
  echo -e "${CYAN}=========================${NC}"
  echo -e "${GREEN}   SCENARIO BUILDER${NC}"
  echo -e "${CYAN}=========================${NC}"
  echo "1. Custom (manual input)"
  echo "2. From Nettool (select list)"
  echo "3. Delete Scenario"
  echo "4. Back"
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
        return
      fi

      if [[ "$scen_name" =~ [[:space:]] ]]; then
        echo -e "${RED}[!] Tidak boleh pakai spasi, gunakan _${NC}"
        return
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
    # 📦 FROM NETTOOL MODE
    # =========================
    2)
      echo -e "${CYAN}=========================${NC}"
      read -p "👉 Nama scenario (tanpa spasi, pakai _): " scen_name

      if [ -z "$scen_name" ]; then
        echo -e "${RED}[!] Nama tidak boleh kosong${NC}"
        return
      fi

      if [[ "$scen_name" =~ [[:space:]] ]]; then
        echo -e "${RED}[!] Tidak boleh pakai spasi, gunakan _${NC}"
        return
      fi

      FILE="$SCENARIO_DIR/${scen_name}.sh"
      > "$FILE"

      echo -e "${CYAN}=========================${NC}"
      echo -e "${GREEN} NETTOOL COMMAND LIST${NC}"
      echo -e "${CYAN}=========================${NC}"

      for i in "${!commands[@]}"; do
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
            echo "$cmd" >> "$FILE"
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
      echo -e "${CYAN}=========================${NC}"
      echo -e "${RED}   DELETE SCENARIO${NC}"
      echo -e "${CYAN}=========================${NC}"

      files=("$SCENARIO_DIR"/*.sh)

      if [ ! -e "${files[0]}" ]; then
        echo -e "${RED}[!] Tidak ada scenario${NC}"
        read -p "ENTER untuk kembali..."
        return
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
        return
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
    4)
      break
      ;;

    *)
      echo -e "${RED}[!] invalid option${NC}"
      sleep 1
      ;;
  esac

done

