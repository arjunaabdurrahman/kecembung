#!/bin/bash

# =========================
# 🔗 NEXUS - KECEMBUNG
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
# 📁 NEXUS PATHS
# =========================
NEXUS_DIR="${NEXUS_DIR:-$HOME/.kecembung/nexus}"
NEXUS_NETWORKS="$NEXUS_DIR/networks"
NEXUS_LOGS="$NEXUS_DIR/logs"
NEXUS_CONF="$NEXUS_DIR/nexus.conf"
NEXUS_VM_CONF="$NEXUS_DIR/vm.conf"
ZT_HOME="${ZT_HOME:-/var/lib/zerotier-one}"
ZT_LOCAL_API="${ZT_LOCAL_API:-http://127.0.0.1:9993}"

# =========================
# 🔍 FIND ZEROTIER BIN
# =========================
find_zt_bin() {
  for p in \
    "$(command -v zerotier-cli 2>/dev/null)" \
    /usr/sbin/zerotier-cli \
    /usr/local/bin/zerotier-cli \
    /usr/bin/zerotier-cli \
    /sbin/zerotier-cli; do
    [ -x "$p" ] && echo "$p" && return 0
  done
  return 1
}

ZT_BIN=$(find_zt_bin)

zt_cli() {
  if [ -n "$ZT_BIN" ]; then
    sudo "$ZT_BIN" "$@"
  else
    sudo zerotier-cli "$@"
  fi
}

# =========================
# 🧾 OUTPUT HELPERS
# =========================
print_line() {
  echo -e "${CYAN}=========================${NC}"
}

print_header() {
  clear
  print_line
  echo -e "${GREEN}$1${NC}"
  print_line
}

press_enter() {
  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

# =========================
# 🔧 DEPENDENCY CHECK
# =========================
check_zerotier() {
  ZT_BIN=$(find_zt_bin)

  if [ -z "$ZT_BIN" ]; then
    echo ""
    echo -e "${YELLOW}[!]${NC} NEXUS tunnel layer belum terinstall"
    echo ""
    read -rp "Install sekarang? (Y/n): " ans
    ans="${ans:-Y}"
    if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
      echo -e "${RED}[!]${NC} NEXUS membutuhkan tunnel layer untuk berjalan"
      return 1
    fi
    echo ""
    echo -e "${CYAN}[~]${NC} Setting up NEXUS tunnel layer..."
    curl -s https://install.zerotier.com | sudo bash >/dev/null 2>&1
    sudo systemctl enable zerotier-one >/dev/null 2>&1
    sudo systemctl start zerotier-one >/dev/null 2>&1
    sleep 5

    ZT_BIN=$(find_zt_bin)
    if [ -z "$ZT_BIN" ]; then
      echo -e "${RED}[!]${NC} Gagal setup tunnel layer. Cek koneksi internet."
      return 1
    fi
    echo -e "${GREEN}[✔]${NC} NEXUS tunnel layer siap"
  fi

  if ! sudo systemctl is-active --quiet zerotier-one 2>/dev/null; then
    echo -e "${CYAN}[~]${NC} Memulai zerotier-one..."
    sudo systemctl start zerotier-one >/dev/null 2>&1
    sleep 3
  fi

  return 0
}

check_deps() {
  command -v jq   >/dev/null 2>&1 || sudo apt install -y jq   >/dev/null 2>&1
  command -v curl >/dev/null 2>&1 || sudo apt install -y curl >/dev/null 2>&1
}

# =========================
# 📂 INIT DIRS
# =========================
init_nexus() {
  mkdir -p "$NEXUS_DIR"
  mkdir -p "$NEXUS_NETWORKS"
  mkdir -p "$NEXUS_LOGS"
  chmod 700 "$NEXUS_DIR"
}

# =========================
# 🔑 CONFIG
# =========================
load_config() {
  NEXUS_ROLE="none"
  NEXUS_NODE_ID=""
  CONTROLLER_IP=""
  CONTROLLER_TOKEN=""
  IS_CONTROLLER=0

  if [ -f "$NEXUS_CONF" ]; then
    source "$NEXUS_CONF"
    NEXUS_ROLE="${ROLE:-none}"
    NEXUS_NODE_ID="${NODE_ID:-}"
    CONTROLLER_IP="${CTRL_IP:-}"
    CONTROLLER_TOKEN="${CTRL_TOKEN:-}"
    IS_CONTROLLER="${CTRL_LOCAL:-0}"
  fi
}

save_config() {
  cat > "$NEXUS_CONF" <<EOF
ROLE=$NEXUS_ROLE
NODE_ID=$NEXUS_NODE_ID
CTRL_IP=$CONTROLLER_IP
CTRL_TOKEN=$CONTROLLER_TOKEN
CTRL_LOCAL=$IS_CONTROLLER
EOF
  chmod 600 "$NEXUS_CONF"
}

# =========================
# 🌐 CONTROLLER API
# =========================
get_auth_token() {
  if [ -f "$ZT_HOME/authtoken.secret" ]; then
    sudo cat "$ZT_HOME/authtoken.secret"
  elif [ -f "$HOME/.zeroTierOneAuthToken" ]; then
    cat "$HOME/.zeroTierOneAuthToken"
  else
    sudo cat "$ZT_HOME/authtoken.secret" 2>/dev/null
  fi
}

ctrl_api() {
  local method="$1"
  local endpoint="$2"
  local data="$3"
  local token base_url

  if [ "$IS_CONTROLLER" -eq 1 ]; then
    token=$(get_auth_token)
    base_url="$ZT_LOCAL_API"
  else
    token="$CONTROLLER_TOKEN"
    base_url="http://$CONTROLLER_IP:9993"
  fi

  if [ -z "$token" ]; then
    echo -e "${RED}[!]${NC} Auth token tidak ditemukan"
    return 1
  fi

  if [ -n "$data" ]; then
    curl -s -X "$method" \
      -H "X-ZT1-Auth: $token" \
      -H "Content-Type: application/json" \
      -d "$data" \
      "$base_url/$endpoint" 2>/dev/null
  else
    curl -s -X "$method" \
      -H "X-ZT1-Auth: $token" \
      "$base_url/$endpoint" 2>/dev/null
  fi
}

# =========================
# 📡 NODE ID
# =========================
get_my_node_id() {
  zt_cli info 2>/dev/null | awk '{print $3}'
}

# =========================
# 📋 PILIH NETWORK
# =========================
select_network() {
  SELECTED_NET=""
  SELECTED_NET_NAME=""

  local nets=()
  local names=()

  while IFS= read -r f; do
    local net_id net_name
    net_id=$(basename "$f")
    net_name=$(grep 'NAME=' "$f" 2>/dev/null | cut -d= -f2)
    [ -z "$net_name" ] && net_name="nexus-$net_id"
    nets+=("$net_id")
    names+=("$net_name")
  done < <(find "$NEXUS_NETWORKS" -type f 2>/dev/null)

  if [ "${#nets[@]}" -eq 0 ]; then
    echo -e "${RED}[!]${NC} Belum ada NEXUS Network."
    press_enter
    return 1
  fi

  if [ "${#nets[@]}" -eq 1 ]; then
    SELECTED_NET="${nets[0]}"
    SELECTED_NET_NAME="${names[0]}"
    return 0
  fi

  echo ""
  echo "Pilih Network:"
  echo ""
  for i in "${!nets[@]}"; do
    echo "$((i+1)). ${names[$i]} (${nets[$i]})"
  done
  echo ""
  read -p "Pilihan: " pick

  if ! [[ "$pick" =~ ^[0-9]+$ ]] || [ "$pick" -lt 1 ] || [ "$pick" -gt "${#nets[@]}" ]; then
    echo -e "${RED}[!]${NC} Pilihan tidak valid"
    press_enter
    return 1
  fi
  pick=$((pick - 1))

  SELECTED_NET="${nets[$pick]}"
  SELECTED_NET_NAME="${names[$pick]}"
  return 0
}

# =========================
# 🏠 HOST SETUP
# =========================
check_controller_capability() {
  local token result

  echo ""

  if [ -n "$ZT_BIN" ]; then
    echo -e "${GREEN}[✔]${NC} ZeroTier terinstall"
  else
    echo -e "${RED}[✘]${NC} ZeroTier belum terinstall"
    return 1
  fi

  if sudo systemctl is-active --quiet zerotier-one 2>/dev/null; then
    echo -e "${GREEN}[✔]${NC} Layanan ZeroTier berjalan"
  else
    echo -e "${RED}[✘]${NC} Layanan ZeroTier tidak berjalan"
    return 1
  fi

  token=$(get_auth_token)
  if [ -n "$token" ]; then
    echo -e "${GREEN}[✔]${NC} Kunci akses ditemukan"
  else
    echo -e "${RED}[✘]${NC} Kunci akses tidak ditemukan"
    return 1
  fi

  result=$(curl -s -X GET \
    -H "X-ZT1-Auth: $token" \
    "$ZT_LOCAL_API/controller" \
    --connect-timeout 5 2>/dev/null)

  if echo "$result" | jq -e '.controller == true and .databaseReady == true' >/dev/null 2>&1; then
    echo -e "${GREEN}[✔]${NC} Mode controller siap digunakan"
  else
    echo -e "${RED}[✘]${NC} Mode controller belum siap"
    return 1
  fi

  return 0
}

setup_controller() {
  print_header "   HOST SETUP - SETUP CONTROLLER"
  echo ""
  echo "1. Laptop ini sebagai controller"
  echo "2. Server lapangan sebagai controller"
  echo "3. Kembali"
  echo ""
  read -p "Pilih menu: " mode

  case "$mode" in
    1)
      echo ""
      echo -e "${CYAN}[~]${NC} Mengecek kemampuan controller lokal..."

      if check_controller_capability; then
        IS_CONTROLLER=1
        NEXUS_ROLE="host"
        NEXUS_NODE_ID=$(get_my_node_id)
        save_config
        echo ""
        echo -e "${GREEN}[✔]${NC} Controller lokal aktif!"
        printf "%-15s : %s\n" "Node ID" "$(get_my_node_id)"
      else
        echo ""
        echo -e "${RED}[!]${NC} ZeroTier controller tidak aktif di mesin ini"
        echo ""
        echo -e "${CYAN}[~]${NC} Kemungkinan penyebab:"
        echo "    - zerotier-one belum support controller mode"
        echo "    - Service belum fully started (tunggu 10 detik)"
        echo "    - Coba: sudo systemctl restart zerotier-one"
        echo ""
        echo -e "${CYAN}[~]${NC} Versi ZeroTier:"
        zt_cli version 2>/dev/null || echo "    tidak terdeteksi"
      fi
      ;;

    2)
      echo ""
      echo -e "${CYAN}[~]${NC} Masukkan detail server lapangan"
      echo ""
      read -p "IP Server Lapangan: " srv_ip
      srv_ip="${srv_ip// /}"

      if [ -z "$srv_ip" ]; then
        echo -e "${RED}[!]${NC} IP tidak boleh kosong"
        press_enter
        return 1
      fi

      echo ""
      echo -e "${YELLOW}[!]${NC} SSH ke server lapangan & jalankan:"
      echo ""
      echo "    sudo cat /var/lib/zerotier-one/authtoken.secret"
      echo ""
      read -p "Paste token di sini: " srv_token
      srv_token="${srv_token// /}"

      if [ -z "$srv_token" ]; then
        echo -e "${RED}[!]${NC} Token tidak boleh kosong"
        press_enter
        return 1
      fi

      echo ""
      echo -e "${CYAN}[~]${NC} Memvalidasi koneksi ke server lapangan..."
      result=$(curl -s -X GET \
        -H "X-ZT1-Auth: $srv_token" \
        "http://$srv_ip:9993/controller" \
        --connect-timeout 5 2>/dev/null)

      if ! echo "$result" | grep -q '"controller"'; then
        echo -e "${RED}[!]${NC} Tidak bisa konek ke controller di $srv_ip"
        echo ""
        echo -e "${CYAN}[~]${NC} Pastikan:"
        echo "    - Server lapangan online & reachable"
        echo "    - Port 9993 tidak diblokir firewall"
        echo "    - zerotier-one jalan di server lapangan"
        echo "    - Token benar (tidak ada spasi)"
        press_enter
        return 1
      fi

      CONTROLLER_IP="$srv_ip"
      CONTROLLER_TOKEN="$srv_token"
      IS_CONTROLLER=0
      NEXUS_ROLE="host"
      NEXUS_NODE_ID=$(get_my_node_id)
      save_config

      echo ""
      echo -e "${GREEN}[✔]${NC} Controller server lapangan terhubung!"
      printf "%-15s : %s\n" "Controller IP" "$srv_ip"
      ;;

    3) return ;;
    *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ;;
  esac

  press_enter
}

create_network() {
  print_header "   HOST SETUP - CREATE NETWORK"
  echo ""

  if [ "$NEXUS_ROLE" != "host" ]; then
    echo -e "${RED}[!]${NC} Setup controller dulu sebelum membuat network"
    press_enter
    return 1
  fi

  RAND_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 4)
  NET_NAME="kcn-$RAND_SUFFIX"

  local ctrl_node
  if [ "$IS_CONTROLLER" -eq 1 ]; then
    ctrl_node=$(get_my_node_id)
  else
    ctrl_node=$(curl -s -X GET \
      -H "X-ZT1-Auth: $CONTROLLER_TOKEN" \
      "http://$CONTROLLER_IP:9993/status" 2>/dev/null | \
      grep -o '"address":"[^"]*"' | cut -d'"' -f4)
  fi

  if [ -z "$ctrl_node" ]; then
    echo -e "${RED}[!]${NC} Tidak bisa mendapatkan Node ID controller"
    press_enter
    return 1
  fi

  RAND_NET=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 6)
  NET_ID="${ctrl_node}${RAND_NET}"

  echo -e "${CYAN}[~]${NC} Membuat NEXUS Network baru..."
  sleep 1

  result=$(ctrl_api POST "controller/network/$NET_ID" "{
    \"name\": \"$NET_NAME\",
    \"private\": true,
    \"v4AssignMode\": {\"zt\": true},
    \"ipAssignmentPools\": [{
      \"ipRangeStart\": \"10.147.0.1\",
      \"ipRangeEnd\": \"10.147.0.254\"
    }],
    \"routes\": [{
      \"target\": \"10.147.0.0/24\",
      \"via\": null
    }]
  }")

  if ! echo "$result" | grep -q '"id"'; then
    echo -e "${RED}[!]${NC} Gagal membuat network"
    echo -e "${CYAN}[~]${NC} Response: $result"
    press_enter
    return 1
  fi

  NET_FILE="$NEXUS_NETWORKS/$NET_ID"
  cat > "$NET_FILE" <<EOF
NAME=$NET_NAME
CREATED=$(date +%s)
CONTROLLER=$CONTROLLER_IP
EOF
  chmod 600 "$NET_FILE"

  echo -e "${CYAN}[~]${NC} Menghubungkan ke network..."
  zt_cli join "$NET_ID" >/dev/null 2>&1
  sleep 3

  MY_NODE=$(get_my_node_id)
  ctrl_api POST "controller/network/$NET_ID/member/$MY_NODE" \
    '{"authorized":true,"activeBridge":false,"description":"Host/Commander"}' >/dev/null 2>&1

  echo ""
  print_line
  echo -e "${GREEN}[✔]${NC} NEXUS Network berhasil dibuat!"
  echo ""
  printf "%-15s : %s\n" "Network Name" "$NET_NAME"
  printf "%-15s : %s\n" "Network ID"   "$NET_ID"
  printf "%-15s : %s\n" "Role"         "Host/Commander"
  printf "%-15s : %s\n" "Tunnel Range" "10.147.0.0/24"
  printf "%-15s : %s\n" "Status"       "Active"
  print_line
  echo ""
  echo -e "${CYAN}[~]${NC} Bagikan Network ID ini ke Agent:"
  echo ""
  echo -e "    ${YELLOW}$NET_ID${NC}"
  echo ""

  press_enter
}

_approve_member() {
  echo ""
  read -rp "Masukkan NEXUS-ID yang di-approve: " mid
  mid="${mid#nxs-}"
  mid="${mid// /}"
  [ -z "$mid" ] && return

  result=$(ctrl_api POST "controller/network/$SELECTED_NET/member/$mid" \
    '{"authorized":true}')

  if echo "$result" | grep -q '"authorized":true'; then
    echo -e "${GREEN}[✔]${NC} nxs-${mid:0:8} berhasil di-approve"
  else
    echo -e "${RED}[!]${NC} Gagal approve — pastikan NEXUS-ID benar"
  fi
  sleep 1
}

_kick_member() {
  echo ""
  read -rp "Masukkan NEXUS-ID yang di-kick: " mid
  mid="${mid#nxs-}"
  mid="${mid// /}"
  [ -z "$mid" ] && return

  ctrl_api POST "controller/network/$SELECTED_NET/member/$mid" \
    '{"authorized":false}' >/dev/null 2>&1

  member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
  mip=$(echo "$member" | grep -o '"ipAssignments":\["[^"]*"' | \
        grep -o '[0-9.]*' | head -1)

  if [ -n "$mip" ] && [ "$mip" != "-" ]; then
    sudo iptables -A INPUT  -s "$mip" -j DROP 2>/dev/null
    sudo iptables -A OUTPUT -d "$mip" -j DROP 2>/dev/null
  fi

  echo -e "${GREEN}[✔]${NC} nxs-${mid:0:8} berhasil di-kick"
  sleep 1
}

_block_member() {
  echo ""
  read -rp "Masukkan NEXUS-ID yang di-block: " mid
  mid="${mid#nxs-}"
  mid="${mid// /}"
  [ -z "$mid" ] && return

  ctrl_api POST "controller/network/$SELECTED_NET/member/$mid" \
    '{"authorized":false}' >/dev/null 2>&1

  member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
  mip=$(echo "$member" | grep -o '"ipAssignments":\["[^"]*"' | \
        grep -o '[0-9.]*' | head -1)

  if [ -n "$mip" ] && [ "$mip" != "-" ]; then
    sudo iptables -A INPUT  -s "$mip" -j DROP 2>/dev/null
    sudo iptables -A OUTPUT -d "$mip" -j DROP 2>/dev/null
  fi

  echo "$mid" >> "$NEXUS_DIR/blocklist"

  echo -e "${GREEN}[✔]${NC} nxs-${mid:0:8} berhasil di-block"
  sleep 1
}

manage_network() {
  select_network || return

  while true; do
    print_header "   MANAGE NETWORK"
    echo "Network : $SELECTED_NET_NAME"
    echo "ID      : $SELECTED_NET"
    print_line
    echo ""

    members_raw=$(ctrl_api GET "controller/network/$SELECTED_NET/member")
    member_ids=$(echo "$members_raw" | tr -d '[]"' | tr ',' '\n' | tr -d ' ')

    printf "%-22s %-16s %-14s %-14s\n" "NEXUS-ID" "Tunnel-IP" "Role" "Status"
    echo -e "${CYAN}----------------------------------------------------------------${NC}"

    if [ -z "$member_ids" ]; then
      echo -e "${YELLOW}  Belum ada member${NC}"
    else
      while IFS= read -r mid; do
        [ -z "$mid" ] && continue
        member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
        mip=$(echo "$member" | grep -o '"ipAssignments":\["[^"]*"' | \
              grep -o '[0-9.]*' | head -1)
        mauth=$(echo "$member" | grep -o '"authorized":[^,}]*' | \
                cut -d: -f2 | tr -d ' ')
        mdesc=$(echo "$member" | grep -o '"description":"[^"]*"' | \
                cut -d'"' -f4)

        [ -z "$mip" ]   && mip="-"
        [ -z "$mdesc" ] && mdesc="Agent"

        if [ "$mauth" = "true" ]; then
          mstatus="${GREEN}Authorized${NC}"
        else
          mstatus="${YELLOW}Pending${NC}"
        fi

        printf "%-22s %-16s %-14s " "nxs-${mid:0:8}" "$mip" "$mdesc"
        echo -e "$mstatus"
      done <<< "$member_ids"
    fi

    echo ""
    print_line
    echo ""
    echo "1. Approve Pending"
    echo "2. Kick Member"
    echo "3. Block Member"
    echo "4. Refresh"
    echo "5. Kembali"
    echo ""
    read -p "Pilih menu: " choice

    case "$choice" in
      1) _approve_member ;;
      2) _kick_member ;;
      3) _block_member ;;
      4) continue ;;
      5) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

network_info() {
  select_network || return

  print_header "   NETWORK INFO"
  echo "Network : $SELECTED_NET_NAME"
  print_line
  echo ""

  members_raw=$(ctrl_api GET "controller/network/$SELECTED_NET/member")
  member_ids=$(echo "$members_raw" | tr -d '[]"' | tr ',' '\n' | tr -d ' ')

  total=0
  authorized=0
  while IFS= read -r mid; do
    [ -z "$mid" ] && continue
    ((total++))
    member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
    mauth=$(echo "$member" | grep -o '"authorized":[^,}]*' | cut -d: -f2 | tr -d ' ')
    [ "$mauth" = "true" ] && ((authorized++))
  done <<< "$member_ids"

  pending=$((total - authorized))

  printf "%-15s : %s\n" "Network Name"   "$SELECTED_NET_NAME"
  printf "%-15s : %s\n" "Network ID"     "$SELECTED_NET"
  printf "%-15s : %s\n" "Total Members"  "$total"
  printf "%-15s : " "Authorized"
  echo -e "${GREEN}$authorized${NC}"
  printf "%-15s : " "Pending"
  echo -e "${YELLOW}$pending${NC}"
  echo ""
  print_line
  echo ""
  echo "Connection Test:"
  echo ""

  while IFS= read -r mid; do
    [ -z "$mid" ] && continue
    member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
    mip=$(echo "$member" | grep -o '"ipAssignments":\["[^"]*"' | \
          grep -o '[0-9.]*' | head -1)
    [ -z "$mip" ] || [ "$mip" = "-" ] && continue

    latency=$(ping -c 2 -W 2 "$mip" 2>/dev/null | \
              grep 'time=' | tail -1 | \
              grep -o 'time=[0-9.]*' | cut -d= -f2)

    if [ -n "$latency" ]; then
      echo -e "${GREEN}[✔]${NC} nxs-${mid:0:8} ($mip) — ${latency}ms"
    else
      echo -e "${RED}[✘]${NC} nxs-${mid:0:8} ($mip) — timeout"
    fi
  done <<< "$member_ids"

  press_enter
}

host_setup_menu() {
  while true; do
    print_header "   HOST SETUP"
    echo ""

    if [ "$NEXUS_ROLE" = "host" ]; then
      if [ "$IS_CONTROLLER" -eq 1 ]; then
        echo -e "${CYAN}[~]${NC} Controller : ${GREEN}Lokal (mesin ini)${NC}"
      else
        echo -e "${CYAN}[~]${NC} Controller : ${GREEN}$CONTROLLER_IP${NC}"
      fi
    else
      echo -e "${YELLOW}[!]${NC} Controller belum disetup"
    fi

    echo ""
    echo "1. Setup Controller"
    echo "2. Create Network"
    echo "3. Manage Network"
    echo "4. Network Info"
    echo "5. Kembali"
    echo ""
    read -p "Pilih menu: " choice

    case "$choice" in
      1) setup_controller ;;
      2) create_network ;;
      3) manage_network ;;
      4) network_info ;;
      5) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

# =========================
# 🔗 JOIN NETWORK
# =========================
join_network() {
  print_header "   JOIN NEXUS NETWORK"
  echo ""
  echo -e "${CYAN}[~]${NC} Masukkan Network ID dari Host"
  echo ""
  read -rp "Network ID: " net_id
  net_id="${net_id// /}"

  if [ -z "$net_id" ]; then
    echo -e "${RED}[!]${NC} Network ID tidak boleh kosong"
    press_enter
    return 1
  fi

  if [ ${#net_id} -ne 16 ]; then
    echo -e "${RED}[!]${NC} Network ID tidak valid (harus 16 karakter)"
    press_enter
    return 1
  fi

  echo ""
  echo -e "${CYAN}[~]${NC} Menghubungkan ke NEXUS Network..."
  sleep 1

  result=$(zt_cli join "$net_id" 2>&1)

  if echo "$result" | grep -q "200 join OK"; then
    NET_FILE="$NEXUS_NETWORKS/$net_id"
    cat > "$NET_FILE" <<EOF
NAME=nexus-${net_id:0:8}
ROLE=agent
JOINED=$(date +%s)
EOF
    chmod 600 "$NET_FILE"

    NEXUS_NODE_ID=$(get_my_node_id)
    NEXUS_ROLE="agent"
    save_config

    echo ""
    print_line
    echo -e "${GREEN}[✔]${NC} Berhasil terhubung ke NEXUS Network!"
    echo ""
    printf "%-15s : %s\n" "Network ID"   "$net_id"
    printf "%-15s : %s\n" "My NEXUS-ID"  "nxs-${NEXUS_NODE_ID:0:8}"
    printf "%-15s : " "Status"
    echo -e "${YELLOW}Menunggu approval Host${NC}"
    print_line
    echo ""
    echo -e "${CYAN}[~]${NC} Hubungi Host untuk mendapatkan approval akses"
  else
    echo ""
    echo -e "${RED}[!]${NC} Gagal terhubung ke NEXUS Network"
    echo -e "${CYAN}[~]${NC} Pastikan Network ID benar dan koneksi aktif"
  fi

  press_enter
}

# =========================
# 👤 MY NEXUS
# =========================
my_identity() {
  print_header "   MY NEXUS - IDENTITY"
  echo ""

  MY_NODE=$(get_my_node_id)
  [ -z "$MY_NODE" ] && MY_NODE="tidak terdeteksi"

  printf "%-15s : %s\n" "NEXUS-ID" "nxs-${MY_NODE:0:8}"
  printf "%-15s : %s\n" "Role"     "${NEXUS_ROLE^}"
  echo ""
  print_line
  echo ""
  echo "Networks yang diikuti:"
  echo ""

  net_list=$(zt_cli listnetworks 2>/dev/null | tail -n +2)

  if [ -z "$net_list" ]; then
    echo -e "${YELLOW}[!]${NC} Belum terhubung ke network manapun"
  else
    while IFS= read -r line; do
      net_id=$(echo "$line" | awk '{print $3}')
      net_status=$(echo "$line" | awk '{print $6}')
      tunnel_ip=$(echo "$line" | awk '{print $NF}' | cut -d/ -f1)

      net_name="unknown"
      [ -f "$NEXUS_NETWORKS/$net_id" ] && \
        net_name=$(grep 'NAME=' "$NEXUS_NETWORKS/$net_id" | cut -d= -f2)

      if [ "$net_status" = "OK" ]; then
        status_out="${GREEN}Connected${NC}"
      else
        status_out="${YELLOW}$net_status${NC}"
      fi

      echo "  $net_name"
      printf "  %-13s : %s\n" "Network ID" "$net_id"
      printf "  %-13s : %s\n" "Tunnel IP"  "$tunnel_ip"
      printf "  %-13s : "     "Status"
      echo -e "$status_out"
      echo ""
    done <<< "$net_list"
  fi

  press_enter
}

connection_test() {
  print_header "   MY NEXUS - CONNECTION TEST"
  echo ""

  select_network || return

  echo ""
  echo -e "${CYAN}[~]${NC} Testing koneksi ke semua node aktif..."
  echo ""

  if [ "$NEXUS_ROLE" = "host" ]; then
    members_raw=$(ctrl_api GET "controller/network/$SELECTED_NET/member")
    member_ids=$(echo "$members_raw" | tr -d '[]"' | tr ',' '\n' | tr -d ' ')

    found=0
    while IFS= read -r mid; do
      [ -z "$mid" ] && continue
      member=$(ctrl_api GET "controller/network/$SELECTED_NET/member/$mid")
      mip=$(echo "$member" | grep -o '"ipAssignments":\["[^"]*"' | \
            grep -o '[0-9.]*' | head -1)
      [ -z "$mip" ] || [ "$mip" = "-" ] && continue
      found=1

      latency=$(ping -c 2 -W 2 "$mip" 2>/dev/null | \
                grep 'time=' | tail -1 | \
                grep -o 'time=[0-9.]*' | cut -d= -f2)

      if [ -n "$latency" ]; then
        echo -e "${GREEN}[✔]${NC} nxs-${mid:0:8} ($mip) — ${latency}ms"
      else
        echo -e "${RED}[✘]${NC} nxs-${mid:0:8} ($mip) — timeout"
      fi
    done <<< "$member_ids"

    [ "$found" -eq 0 ] && echo -e "${YELLOW}[!]${NC} Belum ada member yang terhubung"
  else
    peers=$(zt_cli peers 2>/dev/null | tail -n +2)
    if [ -z "$peers" ]; then
      echo -e "${YELLOW}[!]${NC} Tidak ada peer yang terdeteksi"
    else
      while IFS= read -r peer; do
        peer_id=$(echo "$peer" | awk '{print $1}')
        peer_role=$(echo "$peer" | awk '{print $3}')
        peer_lat=$(echo "$peer" | awk '{print $2}')

        [ "$peer_lat" = "-1" ] \
          && echo -e "${RED}[✘]${NC} nxs-${peer_id:0:8} — offline" \
          || echo -e "${GREEN}[✔]${NC} nxs-${peer_id:0:8} — ${peer_lat}ms ($peer_role)"
      done <<< "$peers"
    fi
  fi

  press_enter
}

network_status() {
  print_header "   MY NEXUS - NETWORK STATUS"
  echo ""

  net_list=$(zt_cli listnetworks 2>/dev/null | tail -n +2)

  if [ -z "$net_list" ]; then
    echo -e "${YELLOW}[!]${NC} Belum terhubung ke network manapun"
  else
    while IFS= read -r line; do
      net_id=$(echo "$line" | awk '{print $3}')
      net_status=$(echo "$line" | awk '{print $6}')
      tunnel_ip=$(echo "$line" | awk '{print $NF}' | cut -d/ -f1)

      net_name="unknown"
      [ -f "$NEXUS_NETWORKS/$net_id" ] && \
        net_name=$(grep 'NAME=' "$NEXUS_NETWORKS/$net_id" | cut -d= -f2)

      if [ "$net_status" = "OK" ]; then
        status_out="${GREEN}Connected & Authorized${NC}"
      elif [ "$net_status" = "ACCESS_DENIED" ]; then
        status_out="${RED}Menunggu Approval Host${NC}"
      else
        status_out="${YELLOW}$net_status${NC}"
      fi

      echo "  $net_name ($net_id)"
      printf "  %-11s : " "Status"
      echo -e "$status_out"
      printf "  %-11s : %s\n" "Tunnel IP" "$tunnel_ip"
      echo ""
    done <<< "$net_list"
  fi

  press_enter
}

my_nexus_menu() {
  while true; do
    print_header "   MY NEXUS"
    echo ""
    echo "1. My ID & Identity"
    echo "2. Connection Test"
    echo "3. Network Status"
    echo "4. Kembali"
    echo ""
    read -p "Pilih menu: " choice

    case "$choice" in
      1) my_identity ;;
      2) connection_test ;;
      3) network_status ;;
      4) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

# =========================
# 🚪 LEAVE NETWORK
# =========================
leave_network() {
  print_header "   LEAVE NEXUS NETWORK"
  echo ""

  select_network || return

  echo ""
  echo -e "${YELLOW}[!]${NC} Kamu akan keluar dari: $SELECTED_NET_NAME"
  echo -e "${YELLOW}[!]${NC} Semua data lokal network ini akan dihapus"
  echo ""
  read -rp "Ketik 'LEAVE' untuk konfirmasi: " confirm

  if [ "$confirm" != "LEAVE" ]; then
    echo -e "${CYAN}[~]${NC} Dibatalkan"
    press_enter
    return
  fi

  echo ""
  echo -e "${CYAN}[~]${NC} Keluar dari NEXUS Network..."

  zt_cli leave "$SELECTED_NET" >/dev/null 2>&1
  rm -f "$NEXUS_NETWORKS/$SELECTED_NET"

  sudo iptables -D INPUT  -s 10.147.0.0/24 -j DROP 2>/dev/null
  sudo iptables -D OUTPUT -d 10.147.0.0/24 -j DROP 2>/dev/null

  echo ""
  echo -e "${GREEN}[✔]${NC} Berhasil keluar dari $SELECTED_NET_NAME"
  echo -e "${CYAN}[~]${NC} Data lokal network telah dihapus"

  press_enter
}

# =========================
# 🔐 VIRTUAL PRIVATE NETWORK
# =========================
vpn_main() {
  init_nexus
  check_zerotier || { press_enter; return; }
  check_deps
  load_config

  while true; do
    MY_NODE=$(get_my_node_id)
    NET_COUNT=$(find "$NEXUS_NETWORKS" -type f 2>/dev/null | wc -l)

    clear
    print_line
    echo -e "${GREEN}   N E X U S  -  VIRTUAL PRIVATE NETWORK${NC}"
    print_line
    printf "%-15s : %s\n" "NEXUS-ID"  "nxs-${MY_NODE:0:8}"
    printf "%-15s : %s\n" "Role"      "${NEXUS_ROLE^}"
    printf "%-15s : %s\n" "Networks"  "$NET_COUNT aktif"
    print_line

    if [ "$NEXUS_ROLE" = "host" ]; then
      if [ "$IS_CONTROLLER" -eq 1 ]; then
        printf "%-15s : %s\n" "Controller" "Lokal"
      else
        printf "%-15s : %s\n" "Controller" "$CONTROLLER_IP"
      fi
    fi

    echo ""
    echo "1. Host Setup"
    echo "2. Join Network"
    echo "3. My Nexus"
    echo "4. Leave Network"
    echo "5. Kembali"
    echo ""
    print_line
    read -p "Pilih menu: " choice

    case "$choice" in
      1) host_setup_menu ;;
      2) join_network ;;
      3) my_nexus_menu ;;
      4) leave_network ;;
      5) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

# =========================
# 🖥️ VIRTUAL MACHINE (MIKROTIK)
# =========================
vm_load_config() {
  VM_ROUTER="mikrotik"
  VM_CLIENT="ubuntu-client"
  VM_ROUTER_IP=""
  VM_CLIENT_IP=""
  VM_CLIENT_USER=""

  [ -f "$NEXUS_VM_CONF" ] && source "$NEXUS_VM_CONF"
}

vm_save_config() {
  cat > "$NEXUS_VM_CONF" <<EOF
VM_ROUTER=$VM_ROUTER
VM_CLIENT=$VM_CLIENT
VM_ROUTER_IP=$VM_ROUTER_IP
VM_CLIENT_IP=$VM_CLIENT_IP
VM_CLIENT_USER=$VM_CLIENT_USER
EOF
  chmod 600 "$NEXUS_VM_CONF"
}

vm_check_deps() {
  if ! command -v virsh >/dev/null 2>&1; then
    echo ""
    echo -e "${YELLOW}[!]${NC} Layer virtualisasi belum terinstall"
    echo ""
    read -rp "Install sekarang? (Y/n): " ans
    ans="${ans:-Y}"
    if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
      echo -e "${RED}[!]${NC} Menu Virtual Machine membutuhkan layer virtualisasi"
      return 1
    fi
    echo ""
    echo -e "${CYAN}[~]${NC} Menginstall layer virtualisasi..."
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-viewer >/dev/null 2>&1

    if ! command -v virsh >/dev/null 2>&1; then
      echo -e "${RED}[!]${NC} Gagal install. Cek koneksi internet."
      return 1
    fi
    echo -e "${GREEN}[✔]${NC} Layer virtualisasi siap"
  fi

  if ! sudo systemctl is-active --quiet libvirtd 2>/dev/null; then
    sudo systemctl start libvirtd >/dev/null 2>&1
    sleep 2
  fi

  return 0
}

vm_state() {
  local s
  s=$(sudo virsh domstate "$1" 2>/dev/null | head -1)
  [ -z "$s" ] && s="tidak ditemukan"
  echo "$s"
}

vm_state_label() {
  case "$1" in
    "running")         echo -e "${GREEN}Running${NC}" ;;
    "shut off")        echo -e "${YELLOW}Stopped${NC}" ;;
    "tidak ditemukan") echo -e "${RED}Tidak ditemukan${NC}" ;;
    *)                 echo -e "${YELLOW}$1${NC}" ;;
  esac
}

# Deteksi IP sebuah VM. Argumen: nama VM, IP manual (opsional)
vm_detect_ip() {
  local vm="$1"
  local manual="$2"
  local ip=""

  # IP manual (menu Pengaturan) diprioritaskan
  if [ -n "$manual" ]; then
    echo "$manual"
    return 0
  fi

  ip=$(sudo virsh domifaddr "$vm" --source lease 2>/dev/null | \
       awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -1)

  if [ -z "$ip" ]; then
    ip=$(sudo virsh domifaddr "$vm" --source arp 2>/dev/null | \
         awk '/ipv4/ {print $4}' | cut -d/ -f1 | head -1)
  fi

  echo "$ip"
}

vm_start() {
  print_header "   VIRTUAL MACHINE - START"
  echo ""

  local vm state ans

  for vm in "$VM_ROUTER" "$VM_CLIENT"; do
    state=$(vm_state "$vm")
    case "$state" in
      "running")
        echo -e "${CYAN}[~]${NC} $vm sudah berjalan"
        ;;
      "tidak ditemukan")
        echo -e "${RED}[✘]${NC} $vm tidak ditemukan di libvirt"
        ;;
      *)
        if sudo virsh start "$vm" >/dev/null 2>&1; then
          echo -e "${GREEN}[✔]${NC} $vm dinyalakan"
        else
          echo -e "${RED}[✘]${NC} Gagal menyalakan $vm"
        fi
        ;;
    esac
  done

  echo ""
  echo -e "${CYAN}[~]${NC} Menunggu VM booting..."
  sleep 4

  echo ""
  sudo virsh list --all

  echo ""
  echo -e "${CYAN}[~]${NC} Akses $VM_CLIENT lewat menu SSH Ubuntu Client"

  press_enter
}

vm_stop() {
  print_header "   VIRTUAL MACHINE - STOP"
  echo ""

  local vm i still

  echo -e "${CYAN}[~]${NC} Mematikan VM..."
  for vm in "$VM_ROUTER" "$VM_CLIENT"; do
    sudo virsh shutdown "$vm" >/dev/null 2>&1
  done

  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    still=0
    for vm in "$VM_ROUTER" "$VM_CLIENT"; do
      [ "$(vm_state "$vm")" = "running" ] && still=1
    done
    [ "$still" -eq 0 ] && break
  done

  for vm in "$VM_ROUTER" "$VM_CLIENT"; do
    if [ "$(vm_state "$vm")" = "running" ]; then
      sudo virsh destroy "$vm" >/dev/null 2>&1
      echo -e "${YELLOW}[!]${NC} $vm dihentikan paksa"
    else
      echo -e "${GREEN}[✔]${NC} $vm berhenti"
    fi
  done

  echo ""
  sudo virsh list --all

  press_enter
}

vm_console() {
  print_header "   VIRTUAL MACHINE - CONSOLE MIKROTIK"
  echo ""

  if [ "$(vm_state "$VM_ROUTER")" != "running" ]; then
    echo -e "${RED}[!]${NC} $VM_ROUTER belum berjalan. Start VM dulu."
    press_enter
    return 1
  fi

  echo -e "${YELLOW}[!]${NC} Keluar dari console: Ctrl + ]"
  echo ""
  sleep 1

  sudo virsh console "$VM_ROUTER"

  press_enter
}

# Cari terminal emulator yang tersedia (untuk SSH di terminal baru)
vm_find_terminal() {
  local t
  for t in gnome-terminal x-terminal-emulator konsole xfce4-terminal mate-terminal xterm; do
    if command -v "$t" >/dev/null 2>&1; then
      echo "$t"
      return 0
    fi
  done
  return 1
}

# Buka SSH ke Ubuntu Client.
# Mode 1 = terminal ini, Mode 2 = terminal baru (otomatis tertutup saat exit)
vm_ssh_client() {
  print_header "   VIRTUAL MACHINE - SSH UBUNTU CLIENT"
  echo ""

  local cip cuser mode term ssh_cmd

  if ! command -v ssh >/dev/null 2>&1; then
    echo -e "${RED}[!]${NC} ssh belum terinstall (sudo apt install openssh-client)"
    press_enter
    return 1
  fi

  if [ "$(vm_state "$VM_CLIENT")" != "running" ]; then
    echo -e "${RED}[!]${NC} $VM_CLIENT belum berjalan. Start VM dulu."
    press_enter
    return 1
  fi

  cip=$(vm_detect_ip "$VM_CLIENT" "$VM_CLIENT_IP")
  if [ -z "$cip" ]; then
    echo -e "${YELLOW}[!]${NC} IP $VM_CLIENT belum terdeteksi"
    echo ""
    echo -e "${CYAN}[~]${NC} Coba:"
    echo "    - Tunggu beberapa detik sampai VM selesai booting"
    echo "    - Atau isi manual lewat menu Pengaturan"
    press_enter
    return 1
  fi

  cuser="$VM_CLIENT_USER"
  if [ -z "$cuser" ]; then
    read -rp "User SSH untuk $VM_CLIENT: " cuser
    cuser="${cuser// /}"
    if [ -z "$cuser" ]; then
      echo -e "${RED}[!]${NC} User tidak boleh kosong"
      press_enter
      return 1
    fi
    VM_CLIENT_USER="$cuser"
    vm_save_config
  fi

  if ! timeout 3 bash -c "</dev/tcp/$cip/22" 2>/dev/null; then
    echo -e "${RED}[!]${NC} Port SSH (22) di $cip tidak terjangkau"
    echo ""
    echo -e "${CYAN}[~]${NC} Pastikan di $VM_CLIENT sudah terpasang SSH server:"
    echo "    sudo apt install openssh-server"
    echo "    sudo systemctl enable --now ssh"
    press_enter
    return 1
  fi

  printf "%-15s : %s\n" "Target" "$cuser@$cip"
  echo ""
  echo "1. SSH di terminal ini"
  echo "2. SSH di terminal baru"
  echo "3. Kembali"
  echo ""
  read -p "Pilih menu: " mode

  ssh_cmd="ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 $cuser@$cip"

  case "$mode" in
    1)
      echo ""
      echo -e "${YELLOW}[!]${NC} Ketik 'exit' untuk kembali ke menu"
      echo ""
      $ssh_cmd
      press_enter
      ;;

    2)
      term=$(vm_find_terminal)
      if [ -z "$term" ]; then
        echo ""
        echo -e "${RED}[!]${NC} Terminal emulator tidak ditemukan"
        echo -e "${CYAN}[~]${NC} Gunakan opsi 1 (terminal ini)"
        press_enter
        return 1
      fi

      case "$term" in
        gnome-terminal|mate-terminal|xfce4-terminal)
          "$term" -- bash -c "$ssh_cmd" >/dev/null 2>&1 &
          ;;
        konsole)
          konsole -e bash -c "$ssh_cmd" >/dev/null 2>&1 &
          ;;
        *)
          "$term" -e bash -c "$ssh_cmd" >/dev/null 2>&1 &
          ;;
      esac
      disown 2>/dev/null

      echo ""
      echo -e "${GREEN}[✔]${NC} Terminal baru dibuka ($cuser@$cip)"
      echo -e "${CYAN}[~]${NC} Ketik 'exit' di sana — terminal itu tertutup, terminal ini tetap jalan"
      sleep 2
      ;;

    3) return ;;
    *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
  esac
}

vm_status() {
  print_header "   VIRTUAL MACHINE - STATUS"
  echo ""

  local rstate cstate rip cip

  rstate=$(vm_state "$VM_ROUTER")
  cstate=$(vm_state "$VM_CLIENT")
  rip=$(vm_detect_ip "$VM_ROUTER" "$VM_ROUTER_IP")
  cip=$(vm_detect_ip "$VM_CLIENT" "$VM_CLIENT_IP")
  [ -z "$rip" ] && rip="belum terdeteksi"
  [ -z "$cip" ] && cip="belum terdeteksi"

  printf "%-15s : " "$VM_ROUTER"
  vm_state_label "$rstate"
  printf "%-15s : " "$VM_CLIENT"
  vm_state_label "$cstate"
  echo ""
  printf "%-15s : %s\n" "IP Mikrotik" "$rip"
  printf "%-15s : %s\n" "IP Client"   "$cip"
  printf "%-15s : %s\n" "User SSH"    "${VM_CLIENT_USER:-belum diatur}"
  echo ""
  print_line
  echo ""
  sudo virsh list --all

  press_enter
}

vm_test() {
  print_header "   VIRTUAL MACHINE - TEST KONEKSI"
  echo ""

  local ip latency entry port label

  if [ "$(vm_state "$VM_ROUTER")" != "running" ]; then
    echo -e "${RED}[!]${NC} $VM_ROUTER belum berjalan. Start VM dulu."
    press_enter
    return 1
  fi

  ip=$(vm_detect_ip "$VM_ROUTER" "$VM_ROUTER_IP")

  if [ -z "$ip" ]; then
    echo -e "${YELLOW}[!]${NC} IP Mikrotik belum terdeteksi"
    echo ""
    echo -e "${CYAN}[~]${NC} Coba:"
    echo "    - Pastikan Mikrotik sudah punya IP (dhcp-client / ip address)"
    echo "    - Atau isi manual lewat menu Pengaturan"
    press_enter
    return 1
  fi

  printf "%-15s : %s\n" "Target" "$ip"
  echo ""

  latency=$(ping -c 2 -W 2 "$ip" 2>/dev/null | \
            grep 'time=' | tail -1 | \
            grep -o 'time=[0-9.]*' | cut -d= -f2)

  if [ -n "$latency" ]; then
    echo -e "${GREEN}[✔]${NC} Ping ($ip) — ${latency}ms"
  else
    echo -e "${RED}[✘]${NC} Ping ($ip) — timeout"
  fi

  echo ""
  echo "Service:"
  echo ""

  for entry in "22:SSH" "80:WebFig" "8291:Winbox" "8728:API"; do
    port="${entry%%:*}"
    label="${entry##*:}"
    if timeout 2 bash -c "</dev/tcp/$ip/$port" 2>/dev/null; then
      echo -e "${GREEN}[✔]${NC} $label (port $port) terbuka"
    else
      echo -e "${RED}[✘]${NC} $label (port $port) tertutup"
    fi
  done

  press_enter
}

_vm_ask_ip() {
  # $1 = label, $2 = nilai saat ini -> hasil di VM_ASK_RESULT
  local label="$1"
  local current="$2"
  local val

  VM_ASK_RESULT="$current"

  printf "%-15s : %s\n" "$label" "${current:-otomatis}"
  read -rp "IP baru (ENTER=tetap, '-'=otomatis): " val
  val="${val// /}"

  if [ -z "$val" ]; then
    return 0
  fi

  if [ "$val" = "-" ]; then
    VM_ASK_RESULT=""
    return 0
  fi

  if ! [[ "$val" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo -e "${RED}[!]${NC} Format IP tidak valid — nilai lama dipertahankan"
    return 1
  fi

  VM_ASK_RESULT="$val"
  return 0
}

vm_settings() {
  print_header "   VIRTUAL MACHINE - PENGATURAN"
  echo ""

  local u

  _vm_ask_ip "IP Mikrotik" "$VM_ROUTER_IP"
  VM_ROUTER_IP="$VM_ASK_RESULT"
  echo ""

  _vm_ask_ip "IP Client" "$VM_CLIENT_IP"
  VM_CLIENT_IP="$VM_ASK_RESULT"
  echo ""

  printf "%-15s : %s\n" "User SSH" "${VM_CLIENT_USER:-belum diatur}"
  read -rp "User baru (ENTER=tetap): " u
  u="${u// /}"
  [ -n "$u" ] && VM_CLIENT_USER="$u"

  vm_save_config

  echo ""
  echo -e "${GREEN}[✔]${NC} Pengaturan disimpan"

  press_enter
}

vm_main() {
  init_nexus
  vm_check_deps || { press_enter; return; }
  vm_load_config

  local rstate cstate

  while true; do
    rstate=$(vm_state "$VM_ROUTER")
    cstate=$(vm_state "$VM_CLIENT")

    clear
    print_line
    echo -e "${GREEN}   N E X U S  -  VIRTUAL MACHINE${NC}"
    print_line
    printf "%-15s : " "$VM_ROUTER"
    vm_state_label "$rstate"
    printf "%-15s : " "$VM_CLIENT"
    vm_state_label "$cstate"
    print_line

    echo ""
    echo "1. Start VM"
    echo "2. Stop VM"
    echo "3. Console Mikrotik"
    echo "4. SSH Ubuntu Client"
    echo "5. Status & IP"
    echo "6. Test Koneksi"
    echo "7. Pengaturan"
    echo "8. Kembali"
    echo ""
    print_line
    read -p "Pilih menu: " choice

    case "$choice" in
      1) vm_start ;;
      2) vm_stop ;;
      3) vm_console ;;
      4) vm_ssh_client ;;
      5) vm_status ;;
      6) vm_test ;;
      7) vm_settings ;;
      8) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

# =========================
# 🚀 NEXUS MAIN
# =========================
nexus_main() {
  init_nexus

  while true; do
    clear
    print_line
    echo -e "${GREEN}         N E X U S${NC}"
    print_line
    echo ""
    echo "1. Virtual Machine"
    echo "2. Virtual Private Network"
    echo "3. Kembali"
    echo ""
    print_line
    read -p "Pilih menu: " choice

    case "$choice" in
      1) vm_main ;;
      2) vpn_main ;;
      3) break ;;
      *) echo -e "${YELLOW}[!]${NC} Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}

# Hanya jalankan nexus_main jika script dijalankan langsung
# (bukan di-source dari kecembung)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  nexus_main
fi
