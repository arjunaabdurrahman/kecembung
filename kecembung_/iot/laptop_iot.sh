#!/bin/bash
# ============================================================
#   [KECEMBUNG TOOLKIT] - IoT Scanner - Laptop Only
#   19 Fitur: 5 Network, 3 WiFi, 3 Bluetooth, 4 Visual, 3 Audio, 1 Physical
#   UI 100% Kecembung Style - Tanpa NEXUS, Tanpa (angka), Tanpa Logs
#   Log: $HOME/.kecembung/logs/iot/
# ============================================================

set +e
set -o pipefail

# =========================
# 🎨 COLORS (Kecembung style)
# Nomor menu sengaja TIDAK diwarnai (putih/default), sisanya berwarna.
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

BASE_DIR="$HOME/.kecembung"
LOG_DIR="$BASE_DIR/logs"
LOG_DIR_IOT="$LOG_DIR/iot"
mkdir -p "$LOG_DIR_IOT" 2>/dev/null

# =========================
# 🧾 EASY OUTPUT SYSTEM (Kecembung style, colorized)
# =========================
print_section() {
  echo ""
  echo -e "${CYAN}==============================${NC}"
  echo -e "${BOLD}${CYAN}  $1${NC}"
  echo -e "${CYAN}==============================${NC}"
}
print_keyval() { printf "${BLUE}%-18s${NC} : %b\n" "$1" "$2"; }
print_success() { echo -e "${GREEN}[✓] $1${NC}"; }
print_error() { echo -e "${RED}[!] $1${NC}"; }
print_info() { echo -e "${YELLOW}[~] $1${NC}"; }
print_warn() { echo -e "${MAGENTA}[⚠] $1${NC}"; }
print_line() { echo -e "${CYAN}------------------------------${NC}"; }
# Item daftar hasil singkat (dipakai di luar parser, misal tampilkan isi QR)
print_item() { echo -e "   ${CYAN}•${NC} $1"; }

get_ts() { date '+%Y-%m-%d_%H-%M-%S'; }
get_local_ip() { ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}'; }
get_subnet() { local ip; ip=$(get_local_ip); if [ -z "$ip" ]; then echo "192.168.1.0/24"; else echo "${ip%.*}.0/24"; fi; }
get_wlan() { iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -1; }

ensure_tool() {
  local bin="$1"; local pkg="${2:-$1}"
  if ! command -v "$bin" &>/dev/null; then
    print_info "$bin belum ada, auto-install $pkg..."
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y "$pkg" >/dev/null 2>&1
    if ! command -v "$bin" &>/dev/null; then print_error "Gagal install $pkg"; return 1; else print_success "$pkg terinstall"; fi
  fi
  return 0
}
log_header() {
  local title="$1" file="$2"
  { echo "=== KECEMBUNG TOOLKIT - $title ==="; echo "Waktu : $(date)"; echo "Host  : $(hostname)"; echo "IP    : $(get_local_ip)"; echo "Subnet: $(get_subnet)"; echo "=============================="; echo ""; } > "$file"
}
note_logfile() { print_info "Hasil mentah/teknis disimpan di: $1 (bisa dibuka pakai text editor kalau perlu detail)"; }
press_enter() { echo ""; read -p "$(echo -e "${CYAN}Tekan ENTER untuk kembali...${NC}")"; }
check_empty_str() {
  local str="$1"; local label="$2"; local tip="$3"
  if [ -z "$(echo "$str" | xargs)" ]; then print_error "Tidak ada $label terdeteksi"; [ -n "$tip" ] && print_info "Tip: $tip"; return 0; fi; return 1
}

# =========================
# 📊 HASIL SUMMARY
# =========================
count_lines() { local s="$1"; [ -z "$s" ] && echo 0 || echo "$s" | grep -c .; }

# =========================
# 🔐 SUDO SESSION (tambahan dari gaya Kecembung, biar gak ditanya password berkali-kali)
# =========================
SUDO_SESSION_ACTIVE=0
SUDO_KEEPALIVE_PID=""
sudo_session_start() {
  [ "$SUDO_SESSION_ACTIVE" -eq 1 ] && return 0
  print_info "Butuh akses administrator (sudo) untuk scan ini"
  if ! sudo -v; then
    print_error "Autentikasi administrator gagal"
    return 1
  fi
  ( while true; do sudo -n true; sleep 60; done ) >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID=$!
  SUDO_SESSION_ACTIVE=1
  return 0
}
sudo_session_stop() {
  [ "$SUDO_SESSION_ACTIVE" -eq 0 ] && return 0
  kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1
  sudo -k
  SUDO_KEEPALIVE_PID=""
  SUDO_SESSION_ACTIVE=0
}
trap sudo_session_stop EXIT

# =========================
# 🔁 CTRL+C → balik ke menu (gaya Kecembung), bukan keluar total
# =========================
RETURN_TO_MENU=0
trap_ctrlc() {
  echo ""
  print_warn "CTRL+C TERDETEKSI → KEMBALI KE MENU"
  RETURN_TO_MENU=1
}
trap trap_ctrlc SIGINT

# =========================
# 🏷️  BANNER
# =========================
print_banner() {
  clear
  echo -e "${CYAN}=================================================${NC}"
  echo -e "${BOLD}${GREEN}        KECEMBUNG TOOLKIT - IOT SCANNER${NC}"
  echo -e "${CYAN}=================================================${NC}"
  echo -e "${YELLOW}  19 Fitur: 5 Network, 3 WiFi, 3 Bluetooth,${NC}"
  echo -e "${YELLOW}            4 Visual, 3 Audio, 1 Physical${NC}"
  print_keyval "Host" "$(hostname)"
  print_keyval "IP Lokal" "$(get_local_ip)"
  print_keyval "Log" "$LOG_DIR_IOT"
  echo -e "${CYAN}=================================================${NC}"
}

# ============================================================
# 🧠 PENERJEMAH OUTPUT - ubah hasil mentah command jadi kalimat
# yang bisa dibaca orang awam (bukan cuma dump teks teknis)
# ============================================================

# Arti tiap port dalam bahasa manusia
friendly_port_name() {
  case "$1" in
    554|8554) echo "biasanya dipakai Kamera CCTV untuk mengirim video (RTSP)" ;;
    80)       echo "halaman pengaturan web perangkat" ;;
    8080)     echo "halaman pengaturan web (port alternatif)" ;;
    8123)     echo "Home Assistant, pusat kendali smart home" ;;
    1883)     echo "MQTT, jalur komunikasi antar perangkat IoT" ;;
    8883)     echo "MQTT versi aman/terenkripsi" ;;
    6668|6669) echo "biasanya Lampu/Saklar pintar merek Tuya" ;;
    55443)    echo "biasanya Lampu pintar merek Yeelight" ;;
    4070)     echo "Spotify Connect pada speaker pintar" ;;
    8008|8009) echo "Google Cast, dipakai Chromecast / Google Home" ;;
    22)       echo "SSH, akses jarak jauh ke perangkat" ;;
    *)        echo "layanan yang belum dikenali toolkit ini" ;;
  esac
}

# Ubah output "nmap" jadi daftar perangkat + port, gaya print_keyval
# (sama kayak cmd_lihat_ip di kecembung: Interface/Status/IP berjejer rapi).
# Return 0 kalau ada perangkat/port terbuka, 1 kalau tidak ada.
parse_nmap_friendly() {
  local raw="$1"
  local current_ip="" found_any=0 found_port=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^Nmap\ scan\ report\ for\ (.+)$ ]]; then
      [ "$found_port" -eq 1 ] && echo ""
      local rest="${BASH_REMATCH[1]}"
      if [[ "$rest" =~ \(([0-9.]+)\)[[:space:]]*$ ]]; then
        current_ip="${BASH_REMATCH[1]}"
      else
        current_ip="$rest"
      fi
      found_port=0
    elif [[ "$line" =~ ^([0-9]+)/tcp[[:space:]]+open[[:space:]]+([^[:space:]]+) ]]; then
      local port="${BASH_REMATCH[1]}" svc="${BASH_REMATCH[2]}"
      if [ "$found_port" -eq 0 ]; then
        print_keyval "IP" "$current_ip"
        found_port=1; found_any=1
      fi
      print_keyval "Port $port" "$svc - $(friendly_port_name "$port")"
    fi
  done <<< "$raw"
  [ "$found_any" -eq 1 ] && return 0 || return 1
}

# Ubah output "arp-scan --localnet" jadi daftar perangkat aktif + vendor.
parse_arpscan_friendly() {
  local raw="$1" any=0
  while IFS=$'\t' read -r ip mac vendor; do
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    any=1
    print_keyval "IP" "$ip"
    print_keyval "MAC" "$mac"
    print_keyval "Vendor" "${vendor:-Tidak diketahui}"
    if [[ "$vendor" =~ (Hikvision|Dahua|Xiongmai|Dafang|Reolink|Ezviz|Foscam) ]]; then
      print_keyval "Catatan" "${RED}Merek ini sering dipakai CCTV${NC}"
    fi
    echo ""
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah output "arp -n" jadi daftar perangkat yang pernah terlihat di jaringan.
parse_arp_friendly() {
  local raw="$1" any=0
  while read -r ip hwtype hwaddr flags iface; do
    [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    any=1
    print_keyval "IP" "$ip"
    print_keyval "MAC" "$hwaddr"
    print_keyval "Interface" "${iface:-?}"
    echo ""
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "iw scan" jadi daftar jaringan WiFi sekitar.
parse_wifi_scan_friendly() {
  local raw="$1" mac="" ssid="" signal="" any=0
  _flush_wifi() {
    [ -z "$mac" ] && return
    print_keyval "SSID" "${ssid:-<tersembunyi>}"
    print_keyval "Sinyal" "${signal:-tidak diketahui}"
    echo ""
  }
  while IFS= read -r line; do
    if [[ "$line" =~ ^BSS[[:space:]]([0-9A-Fa-f:]+) ]]; then
      _flush_wifi
      mac="${BASH_REMATCH[1]}"; ssid=""; signal=""; any=1
    elif [[ "$line" =~ SSID:[[:space:]]*(.*)$ ]]; then
      ssid="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ signal:[[:space:]]*(.*)$ ]]; then
      signal="${BASH_REMATCH[1]}"
    fi
  done <<< "$raw"
  _flush_wifi
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "iw scan | grep primary channel | sort | uniq -c" jadi kepadatan channel.
parse_channel_friendly() {
  local raw="$1" any=0
  while read -r count _ _ channel; do
    [[ "$count" =~ ^[0-9]+$ ]] || continue
    any=1
    local level="Sepi"
    [ "$count" -ge 5 ] && level="${RED}Padat sekali${NC}"
    [ "$count" -ge 3 ] && [ "$count" -lt 5 ] && level="${YELLOW}Lumayan padat${NC}"
    print_keyval "Channel $channel" "dipakai $count WiFi lain ($level)"
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "hcitool scan" / "hcitool lescan" jadi daftar perangkat Bluetooth.
parse_bt_friendly() {
  local raw="$1" any=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*(([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})[[:space:]]+(.*)$ ]]; then
      any=1
      local mac="${BASH_REMATCH[1]}" name="${BASH_REMATCH[3]}"
      print_keyval "Nama" "${name:-Tanpa nama}"
      print_keyval "MAC" "$mac"
      echo ""
    fi
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "bluetoothctl scan on" jadi daftar perangkat Bluetooth.
parse_btctl_friendly() {
  local raw="$1" any=0 line mac name
  while IFS= read -r line; do
    [[ "$line" =~ Device\ (([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2})\ (.*)$ ]] || continue
    mac="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[3]}"
    any=1
    print_keyval "Nama" "${name:-Tanpa nama}"
    print_keyval "MAC" "$mac"
    echo ""
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "avahi-browse -alrt" jadi daftar TV/Speaker/perangkat cast.
# Ambil dari baris "hostname = [...]" / "address = [...]" / "port = [...]"
# (bukan dari baris ringkasan kolom yang suka geser - lebih akurat).
parse_avahi_friendly() {
  local raw="$1" any=0 name="" addr="" port=""
  _flush_avahi() {
    [ -z "$name" ] && [ -z "$addr" ] && return
    print_keyval "Nama" "${name:-tidak diketahui}"
    print_keyval "IP" "${addr:-tidak diketahui}"
    [ -n "$port" ] && print_keyval "Port" "$port"
    echo ""
  }
  while IFS= read -r line; do
    if [[ "$line" =~ ^[=+][[:space:]] ]]; then
      _flush_avahi
      name=""; addr=""; port=""
    elif [[ "$line" =~ hostname[[:space:]]*=[[:space:]]*\[([^]]+)\] ]]; then
      name="${BASH_REMATCH[1]%.local}"; any=1
    elif [[ "$line" =~ address[[:space:]]*=[[:space:]]*\[([^]]+)\] ]]; then
      addr="${BASH_REMATCH[1]}"; any=1
    elif [[ "$line" =~ port[[:space:]]*=[[:space:]]*\[([^]]+)\] ]]; then
      port="${BASH_REMATCH[1]}"
    fi
  done <<< "$raw"
  _flush_avahi
  [ "$any" -eq 1 ] && return 0 || return 1
}

# Ubah hasil "lsusb" jadi daftar perangkat USB yang nyolok.
parse_lsusb_friendly() {
  local raw="$1" any=0
  while IFS= read -r line; do
    [[ "$line" =~ ID\ ([0-9a-fA-F]{4}:[0-9a-fA-F]{4})[[:space:]]*(.*)$ ]] || continue
    any=1
    local nm="${BASH_REMATCH[2]}"
    print_keyval "Perangkat" "${nm:-Tidak dikenal}"
    print_keyval "ID" "${BASH_REMATCH[1]}"
    echo ""
  done <<< "$raw"
  [ "$any" -eq 1 ] && return 0 || return 1
}

net_mdns_ssdp() {
  clear; print_section "NETWORK - TV & SPEAKER"
  local out="$LOG_DIR_IOT/N1_mdns_ssdp_$(get_ts).txt"; log_header "N1 - mDNS" "$out"
  ensure_tool avahi-browse avahi-utils
  print_info "Mencari TV, speaker, atau Chromecast yang nyambung di WiFi yang sama (8 detik)..."
  echo ""; local result; result=$(timeout 8 avahi-browse -alrt 2>/dev/null)
  echo "$result" | tee -a "$out" >/dev/null
  if parse_avahi_friendly "$result"; then
    echo ""; print_success "Scan selesai"
  else
    print_error "Tidak ada TV/Speaker terdeteksi via mDNS"; print_info "Tip: Pastikan satu WiFi, cek avahi-browse -alrt"
  fi
  echo ""; note_logfile "$out"; press_enter
}
net_cctv_plug() {
  clear; print_section "NETWORK - CCTV & COLOKAN"
  local out="$LOG_DIR_IOT/N2_cctv_$(get_ts).txt"; log_header "N2 - CCTV" "$out"
  ensure_tool nmap nmap; local subnet=$(get_subnet); print_keyval "Jaringan dicek" "$subnet"; print_info "Mencari kamera CCTV & colokan pintar di jaringan ini..."
  sudo_session_start
  echo ""; local result; result=$(sudo nmap -sS -p 554,8554,80,8080 --open "$subnet" 2>/dev/null)
  echo "$result" | tee -a "$out" >/dev/null
  if parse_nmap_friendly "$result"; then
    echo ""; print_success "Ditemukan host CCTV / colokan pintar"
  else
    print_error "Tidak ada CCTV / Smart Plug terdeteksi"; print_info "Tip: Coba scan kamera tersembunyi"
  fi
  echo ""; note_logfile "$out"; press_enter
}
net_smarthome_hub() {
  clear; print_section "NETWORK - PUSAT SMART HOME"
  local out="$LOG_DIR_IOT/N3_hub_$(get_ts).txt"; log_header "N3 - Hub" "$out"
  ensure_tool nmap nmap; local subnet=$(get_subnet); print_keyval "Jaringan dicek" "$subnet"; print_info "Mencari hub pusat smart home (Home Assistant/MQTT)..."
  sudo_session_start
  echo ""; local result; result=$(sudo nmap -sS -p 8123,1883,8883,80 --open "$subnet" 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_nmap_friendly "$result"; then
    echo ""; print_success "Ditemukan Hub Smart Home"
  else
    print_error "Tidak ada Pusat Smart Home terdeteksi"; print_info "Tip: Home Assistant 8123, MQTT 1883"
  fi
  echo ""; note_logfile "$out"; press_enter
}
net_hidden_cam() {
  clear; print_section "NETWORK - KAMERA TERSEMBUNYI"
  local out="$LOG_DIR_IOT/N4_hidden_$(get_ts).txt"; log_header "N4 - Hidden" "$out"
  ensure_tool arp-scan arp-scan; print_info "Mendata semua perangkat yang aktif di jaringan lokal..."
  sudo_session_start
  echo ""; local result; result=$(sudo arp-scan --localnet 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_arpscan_friendly "$result"; then
    echo ""; print_success "Host aktif tersimpan"; print_info "Perangkat berwarna merah = merek yang sering dipakai kamera tersembunyi"
  else
    print_error "Tidak ada perangkat mencurigakan terdeteksi"; print_info "Tip: Cek WiFi & sudo arp-scan --localnet"
  fi
  echo ""; note_logfile "$out"; press_enter
}
net_lamp_switch() {
  clear; print_section "NETWORK - LAMPU & SAKLAR"
  local out="$LOG_DIR_IOT/N5_lampu_$(get_ts).txt"; log_header "N5 - Lampu" "$out"
  ensure_tool nmap nmap; local subnet=$(get_subnet); print_keyval "Jaringan dicek" "$subnet"; print_info "Mencari lampu/saklar pintar (Tuya, Yeelight, dll)..."
  sudo_session_start
  echo ""; local result; result=$(sudo nmap -sS -p 6668,6669,55443 -T4 --open "$subnet" 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_nmap_friendly "$result"; then
    echo ""; print_success "Ditemukan Lampu/Saklar"
  else
    print_error "Tidak ada Lampu / Saklar Pintar terdeteksi"; print_info "Tip: Tuya 6668, satu jaringan"
  fi
  echo ""; note_logfile "$out"; press_enter
}
wifi_new_devices() {
  clear; print_section "WIFI - CARI PERANGKAT BARU"
  local out="$LOG_DIR_IOT/W1_new_$(get_ts).txt"; log_header "W1" "$out"
  ensure_tool iw iw; local wlan=$(get_wlan)
  if [ -z "$wlan" ]; then print_error "Tidak ada interface WiFi terdeteksi"; print_info "Tip: iw dev"; press_enter; return; fi
  print_keyval "Interface" "$wlan"; print_info "Mencari semua jaringan WiFi di sekitar laptop ini..."
  sudo_session_start
  echo ""; local result; result=$(sudo iw dev "$wlan" scan 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_wifi_scan_friendly "$result"; then
    echo ""; print_success "SSID ditemukan"
  else
    print_error "Tidak ada jaringan WiFi terdeteksi"; print_info "Tip: Dekatkan router, sudo iw dev $wlan scan"
  fi
  echo ""; note_logfile "$out"; press_enter
}
wifi_trace() {
  clear; print_section "WIFI - LACAK JEJAK"
  local out="$LOG_DIR_IOT/W2_trace_$(get_ts).txt"; log_header "W2" "$out"
  print_info "Melihat perangkat yang pernah berkomunikasi dengan laptop ini (ARP cache)..."
  echo ""; local result; result=$(arp -n 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_arp_friendly "$result"; then
    echo ""; print_success "Jejak ARP tersimpan"
  else
    print_error "Tidak ada jejak ARP terdeteksi"; print_info "Tip: ping gateway dulu"
  fi
  echo ""; note_logfile "$out"; press_enter
}
wifi_interference() {
  clear; print_section "WIFI - CEK GANGGUAN"
  local out="$LOG_DIR_IOT/W3_interference_$(get_ts).txt"; log_header "W3" "$out"
  ensure_tool iw iw; local wlan=$(get_wlan)
  if [ -z "$wlan" ]; then print_error "Tidak ada interface WiFi"; print_info "Tip: iw dev"; press_enter; return; fi
  print_keyval "Interface" "$wlan"; print_info "Mengecek seberapa padat channel WiFi di sekitar sini..."
  sudo_session_start
  echo ""; local result; result=$(sudo iw dev "$wlan" scan 2>/dev/null | grep "primary channel" | sort | uniq -c | sort -rn); echo "$result" | tee -a "$out" >/dev/null
  if parse_channel_friendly "$result"; then
    echo ""; print_success "Analisa selesai"
  else
    print_error "Tidak ada data channel WiFi terdeteksi"; print_info "Tip: sudo iw dev $wlan scan | grep channel"
  fi
  echo ""; note_logfile "$out"; press_enter
}
bt_lock_watch() {
  clear; print_section "BLUETOOTH - KUNCI & JAM"
  local out="$LOG_DIR_IOT/B1_lock_$(get_ts).txt"; log_header "B1" "$out"
  ensure_tool hcitool bluez; sudo hciconfig hci0 up 2>/dev/null; print_info "Mencari gembok pintar / jam tangan Bluetooth di sekitar (10 detik)..."
  echo ""; local result; result=$(timeout 10 hcitool scan 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_bt_friendly "$result"; then
    echo ""; print_success "BT ditemukan"
  else
    print_error "Tidak ada perangkat Bluetooth (Kunci/Jam) terdeteksi"; print_info "Tip: Bluetooth ON, rfkill unblock bluetooth"
  fi
  echo ""; note_logfile "$out"; press_enter
}
bt_tracker() {
  clear; print_section "BLUETOOTH - PELACAK"
  local out="$LOG_DIR_IOT/B2_tracker_$(get_ts).txt"; log_header "B2" "$out"
  ensure_tool hcitool bluez; sudo hciconfig hci0 up 2>/dev/null; print_info "Mencari pelacak BLE seperti AirTag/Tile di sekitar (10 detik)..."
  echo ""; local result; result=$(timeout 10 hcitool lescan --passive 2>/dev/null)
  local via_ctl=0
  if [ -z "$result" ] && command -v bluetoothctl &>/dev/null; then result=$(timeout 10 bluetoothctl --timeout 10 scan on 2>&1 | head -n 50); via_ctl=1; fi
  echo "$result" | tee -a "$out" >/dev/null
  local hit=1
  if [ "$via_ctl" -eq 1 ]; then parse_btctl_friendly "$result"; hit=$?; else parse_bt_friendly "$result"; hit=$?; fi
  if [ "$hit" -eq 0 ]; then
    echo ""; print_success "Tracker tertangkap"
  else
    print_error "Tidak ada pelacak BLE terdeteksi"; print_info "Tip: bluetoothctl scan on, pastikan BLE support"
  fi
  echo ""; note_logfile "$out"; press_enter
}
bt_ble_sensor() {
  clear; print_section "BLUETOOTH - SENSOR KECIL"
  local out="$LOG_DIR_IOT/B3_ble_$(get_ts).txt"; log_header "B3" "$out"
  ensure_tool hcitool bluez; sudo hciconfig hci0 up 2>/dev/null; print_info "Mencari sensor BLE kecil (suhu, pintu, gerak) di sekitar (10 detik)..."
  echo ""; local result; result=$(timeout 10 hcitool lescan --passive 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_bt_friendly "$result"; then
    echo ""; print_success "Sensor terdeteksi"
  else
    print_error "Tidak ada sensor BLE kecil terdeteksi"; print_info "Tip: Mode pairing, dekatkan laptop"
  fi
  echo ""; note_logfile "$out"; press_enter
}
visual_ir() {
  clear; print_section "VISUAL - KILATAN REMOTE"
  print_info "Cara cek apakah remote masih punya baterai/aktif lewat kamera laptop:"; print_line
  echo "  1. Buka Cheese/guvcview"; echo "  2. Arahkan remote ke kamera"; echo "  3. Tekan tombol"; echo "  4. Kilatan ungu/putih = IR aktif"; echo ""
  if [ ! -e /dev/video0 ]; then print_error "Tidak ada kamera /dev/video0 terdeteksi"; print_info "Tip: ls /dev/video*"; else print_success "Kamera /dev/video0 tersedia, siap dipakai"; print_keyval "Device" "/dev/video0"; fi
  echo ""; press_enter
}
visual_blink() {
  clear; print_section "VISUAL - KEDIPAN LAMPU"
  echo -e "  ${BOLD}Arti kedipan LED di perangkat IoT:${NC}"; print_line
  echo "  1x lambat = Standby"; echo "  2x cepat = Connecting"; echo "  3x = Pairing"; echo "  Cepat terus = Error"; echo "  Solid = Connected"; echo ""; print_info "Perhatikan lampunya langsung sambil pegang stopwatch"; press_enter
}
visual_motion() {
  clear; print_section "VISUAL - PERGERAKAN"
  print_info "Pakai kamera laptop untuk memantau gerakan di sekitar ruangan"; echo ""
  if [ ! -e /dev/video0 ]; then print_error "Tidak ada kamera /dev/video0 terdeteksi"; print_info "Tip: apt install motion"; else print_success "Kamera tersedia dan siap dipakai"; print_keyval "Device" "/dev/video0"; fi
  echo ""; press_enter
}
visual_qr() {
  clear; print_section "VISUAL - BACA QR PERANGKAT"
  ensure_tool zbarcam zbar-tools
  if [ ! -e /dev/video0 ]; then print_error "Tidak ada kamera /dev/video0 terdeteksi"; print_info "Tip: QR di belakang IoT"; echo ""; press_enter; return; fi
  print_info "Arahkan kamera ke stiker QR di belakang perangkat IoT (15 detik)..."; echo ""; local result; result=$(timeout 15 zbarcam --raw --quiet /dev/video0 2>/dev/null)
  if check_empty_str "$result" "kode QR" "QR terang fokus 10-20cm"; then :; else print_success "QR berhasil dibaca, isinya:"; print_item "${GREEN}$result${NC}"; fi
  echo ""; press_enter
}
audio_ultrasonic() {
  clear; print_section "AUDIO - SUARA HALUS"
  ensure_tool sox sox; local wav="$LOG_DIR_IOT/ultrasonic_$(get_ts).wav"; print_info "Merekam 5 detik untuk menangkap suara ultrasonic (di luar pendengaran manusia)"; print_keyval "File rekaman" "$wav"; echo ""
  if sox -d -t wav "$wav" trim 0 5 2>/dev/null; then print_success "Rekaman tersimpan, aman dibuka kapan saja"; print_info "Untuk lihat grafik suaranya: sox $wav -n spectrogram"; else print_error "Gagal rekam mic"; print_info "Tip: pavucontrol, arecord -l"; fi
  echo ""; press_enter
}
audio_assistant() {
  clear; print_section "AUDIO - ASISTEN PINTAR"
  ensure_tool nmap nmap; local subnet=$(get_subnet); print_keyval "Jaringan dicek" "$subnet"; print_info "Mencari speaker/asisten pintar (Google Home dll)..."
  sudo_session_start
  echo ""; local out="$LOG_DIR_IOT/A2_assistant_$(get_ts).txt"; log_header "A2" "$out"; local result; result=$(sudo nmap -sS -p 4070,8008,8009 --open "$subnet" 2>/dev/null); echo "$result" | tee -a "$out" >/dev/null
  if parse_nmap_friendly "$result"; then
    echo ""; print_success "Asisten ditemukan"
  else
    print_error "Tidak ada Asisten Pintar terdeteksi"; print_info "Tip: Google Home 8008/8009"
  fi
  echo ""; note_logfile "$out"; press_enter
}
audio_machine_fp() {
  clear; print_section "AUDIO - SUARA MESIN"
  ensure_tool sox sox; local wav="$LOG_DIR_IOT/machine_$(get_ts).wav"; print_info "Merekam 5 detik suara mesin untuk dianalisa volumenya"; print_keyval "File rekaman" "$wav"; echo ""
  if sox -d -t wav "$wav" trim 0 5 2>/dev/null; then
    local stat; stat=$(sox "$wav" -n stat 2>&1)
    local rms; rms=$(echo "$stat" | grep -i "RMS.*amplitude" | awk '{print $NF}')
    if [ -z "$rms" ]; then
      print_error "Gagal analisa"
    else
      print_success "Fingerprint selesai"
      local level; level=$(awk -v r="$rms" 'BEGIN{ if (r+0 > 0.3) print "KERAS"; else if (r+0 > 0.05) print "SEDANG"; else print "PELAN/HALUS" }')
      print_keyval "Volume" "$level (RMS $rms)"
    fi
  else
    print_error "Gagal rekam mic"; print_info "Tip: arecord -l"
  fi
  echo ""; press_enter
}
physical_usb() {
  clear; print_section "PHYSICAL - CEK COLOKAN USB"
  local out="$LOG_DIR_IOT/P1_usb_$(get_ts).txt"; log_header "P1" "$out"
  print_info "Mendata semua perangkat yang tercolok lewat USB..."; echo ""
  local result; result=$(lsusb 2>/dev/null)
  { echo "$result"; echo ""; echo "--- dmesg USB 10 terakhir ---"; dmesg | grep -i usb | tail -10; } | tee -a "$out" >/dev/null
  if parse_lsusb_friendly "$result"; then
    echo ""; print_success "$(count_lines "$result") perangkat USB terdeteksi"
  else
    print_error "Tidak ada perangkat USB terdeteksi"; print_info "Tip: driver USB"
  fi
  echo ""; note_logfile "$out"; press_enter
}

menu_network() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "NETWORK"
    echo "1. Lihat TV & Speaker"; echo "2. Lihat CCTV & Colokan"; echo "3. Lihat Pusat Smart Home"; echo "4. Lihat Kamera Tersembunyi"; echo "5. Lihat Lampu & Saklar"; echo "6. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) net_mdns_ssdp;; 2) net_cctv_plug;; 3) net_smarthome_hub;; 4) net_hidden_cam;; 5) net_lamp_switch;; 6) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}
menu_wifi() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "WIFI"
    echo "1. Cari Perangkat Baru"; echo "2. Lacak Jejak Perangkat"; echo "3. Cek Gangguan WiFi"; echo "4. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) wifi_new_devices;; 2) wifi_trace;; 3) wifi_interference;; 4) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}
menu_bluetooth() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "BLUETOOTH"
    echo "1. Lihat Kunci & Jam"; echo "2. Lihat Pelacak"; echo "3. Lihat Sensor Kecil"; echo "4. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) bt_lock_watch;; 2) bt_tracker;; 3) bt_ble_sensor;; 4) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}
menu_visual() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "VISUAL"
    echo "1. Lihat Kilatan Remote"; echo "2. Lihat Kedipan Lampu"; echo "3. Lihat Pergerakan"; echo "4. Baca QR Perangkat"; echo "5. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) visual_ir;; 2) visual_blink;; 3) visual_motion;; 4) visual_qr;; 5) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}
menu_audio() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "AUDIO"
    echo "1. Dengar Suara Halus"; echo "2. Dengar Asisten Pintar"; echo "3. Dengar Suara Mesin"; echo "4. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) audio_ultrasonic;; 2) audio_assistant;; 3) audio_machine_fp;; 4) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}
menu_physical() {
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "PHYSICAL"
    echo "1. Cek Colokan USB"; echo "2. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" o
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $o in 1) physical_usb;; 2) break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
}

main_iot() {
  print_banner
  while true; do
    RETURN_TO_MENU=0
    clear; print_section "IOT SCANNER"
    echo "1. Network"
    echo "2. WiFi"
    echo "3. Bluetooth"
    echo "4. Visual"
    echo "5. Audio"
    echo "6. Physical"
    echo "7. Kembali"
    echo -e "${CYAN}==============================${NC}"
    read -p "$(echo -e "${CYAN}Pilih menu: ${NC}")" m
    [ "$RETURN_TO_MENU" -eq 1 ] && continue
    case $m in 1) menu_network;; 2) menu_wifi;; 3) menu_bluetooth;; 4) menu_visual;; 5) menu_audio;; 6) menu_physical;; 7) print_success "Kembali ke Kecembung Utama..."; break;; *) print_error "Pilihan tidak valid"; press_enter;; esac
  done
  sudo_session_stop
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main_iot; fi