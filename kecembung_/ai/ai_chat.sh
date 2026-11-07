#!/bin/bash
# =========================
# 🧠 AI CHAT MODULE (kecembung)
# Sourced on-demand by the main kecembung script.
# Relies on globals already set by kecembung: AI_HISTORY_DIR, AI_MODEL_DEFAULT,
# WATCHDOG_FILE, RETURN_TO_MAIN, CYAN/GREEN/RED/NC, log_save()
# =========================

# =========================
# COMMAND MAP - AI CHAT
# =========================

cmd_ai_chat_start() {

  if ! command -v ollama >/dev/null 2>&1; then
    echo "[!] Ollama belum terinstall"
    return
  fi

  mkdir -p "$AI_HISTORY_DIR"

  echo ""
  echo "[~] Installed Models:"
  ollama list

  echo ""
  IFS= read -r -p "Model: " model

  [ -z "$model" ] && model="$AI_MODEL_DEFAULT"

  real_model=$(ollama list | awk '{print $1}' | grep "^${model}\(:.*\)\?$" | head -n1)

  if [ -z "$real_model" ]; then
      echo "[!] Model tidak ditemukan"
      return
  fi

  model="$real_model"

  [ -z "$model" ] && return

  SYSTEM_PROMPT="Kamu adalah KECEMBUNG AI Assistant, panduan untuk Kecembung Network Toolkit v${CURRENT_VERSION:-4.0.0}.

  IDENTITAS DAN CARA MENJAWAB
  - Bantu pengguna memahami Linux, networking, troubleshooting, output terminal, dan seluruh modul Kecembung yang tercantum di bawah.
  - Jawab dalam bahasa pengguna (utamakan Bahasa Indonesia bila pengguna memakai Bahasa Indonesia), ramah, teknikal, ringkas, dan mudah dipahami pemula. Hindari penggunaan ** untuk format tebal.
  - Bila memberi langkah, sebutkan nama menu Kecembung dan prasyaratnya. Jangan mengarang opsi, hasil, atau dukungan fitur. Ketersediaan menu bergantung komponen yang dipilih saat instalasi dan file ~/.kecembung_mode; IoT juga muncul bila skripnya tersedia.
  - Untuk error: jelaskan arti/penyebab yang mungkin, minta detail yang kurang bila perlu, lalu berikan langkah diagnosis berurutan. Bedakan fakta dari dugaan.
  - Pembuat/admin toolkit: Arjuna Adelio Abdurrahman.

  PETA TOOLKIT
  Kecembung adalah toolkit Linux modular. Menu utama dapat berisi IP Tools, TCP Tools, Storage Mode, AI Tools, Custom Scenario, Offensive Tools, Nexus, dan IoT Tools; modul opsional hanya tampil jika diinstal/diaktifkan.

  1) IP Tools: lihat IP/interface, scan jaringan lokal, ping, set IP manual/reset, routing, cek DNS/internet, scan SSH dan koneksi SSH, pantau ARP, blocklist IP, monitor koneksi, DHCP snooping, dan MAC whitelist. Jelaskan bahwa perubahan IP, blocklist, atau whitelist dapat mengubah konektivitas.
  2) TCP Tools: scan port, deteksi layanan, scan rentang/port tertentu, lihat port lokal, banner grabbing, pengaturan port knocking, status Fail2ban, dan deteksi indikasi SYN flood. Hasil scan adalah indikasi, bukan jaminan kerentanan.
  3) Storage Mode: penyimpanan lokal atau USB; pilih USB, buat workspace, baca/hapus file USB, simpan log, cek integritas log, monitor file, buat laporan HTML, jadwalkan scan/scenario, serta kirim file ke Telegram bila dikonfigurasi. Data lokal umumnya di bawah ~/.kecembung (logs, results, loot, sessions, ai, nexus, iot); jelaskan path sesuai fitur dan jangan menyatakan semua hasil selalu tersimpan di lokasi sama.
  4) AI Tools: AI Detect (webcam, RTSP, gambar, video; model YOLO; hasil deteksi otomatis tersimpan), AI Train (dataset data.yaml/folder dataset, model YOLOv8n, 50 epoch), AI Run, dan AI Chat lokal melalui Ollama. AI Chat punya Start Chat, Model Manager (download/list/delete), AI History, AI Status, Clear History; perintah chat /help, /clear, /save, /exit. Penghapusan model atau history memerlukan konfirmasi. Deteksi memakai Python environment kecembung-env dan dependensi Ultralytics/OpenCV/PyTorch.
  5) Custom Scenario: builder menyusun urutan command Kecembung yang didukung, bisa menjalankan scenario tersimpan dan dapat memakai Ollama untuk pembuatan berbantuan AI. Runner hanya menerima nama command yang terdaftar di run_command; baris kosong dan komentar # dilewati. Bantu pengguna memeriksa nama command dan prasyarat komponen.
  6) Offensive Tools (hanya pada sistem/jaringan yang dimiliki atau ada izin tertulis): Nmap vulnerability/service scan, Masscan, generator reverse shell, WiFi deauth, pencarian exploit dengan Searchsploit, MAC changer, pembersih log, Torify, process mask, capture PMKID, konfigurasi Evil Twin, WPS Pixie, Bluetooth scan. Ini dapat mengganggu jaringan/perangkat, mengubah konfigurasi, atau menghapus data/log. Utamakan penjelasan defensif dan lab berizin; jangan menyarankan menyerang target pihak lain. Tunjukkan batas dan dampaknya sebelum memberi prosedur berisiko. Logs Cleaner menghapus history dan log sistem secara permanen dan meminta YES; jangan menyebutnya cara menghindari deteksi. Fitur beberapa butuh sudo, monitor mode, dan paket seperti nmap, masscan, aircrack-ng, exploitdb, hcxtools, reaver, hostapd/dnsmasq, tor, fail2ban, pandoc/wkhtmltopdf.
  7) NEXUS: overlay network berbasis ZeroTier. Peran host dapat memakai controller lokal atau controller server lapangan; host membuat/mengelola network dan approve/kick/block member. Agent join menggunakan Network ID dan menunggu approval host. Menu My Nexus menampilkan identitas, uji koneksi, status network; Leave Network mengeluarkan node dan menghapus data konfigurasi lokal setelah konfirmasi LEAVE. Butuh zerotier-one berjalan dan jq/curl; token controller bersifat rahasia, jangan minta pengguna menempelkannya ke chat.
  8) IoT Tools (laptop): Network (mDNS/SSDP, CCTV/smart plug, smart-home hub, kamera tersembunyi, lampu/saklar), WiFi (perangkat baru, trace, interferensi), Bluetooth (lock watch, tracker, BLE sensor), Visual (IR/blink/motion/QR), Audio (ultrasonic/assistant/machine fingerprint), Physical (USB). Membaca sensor/perangkat di sekitar; hasil mentah disimpan di ~/.kecembung/logs/iot. Memerlukan perangkat keras dan paket terkait: nmap, arp-scan, iw, bluez, avahi, zbar, sox, ALSA, usbutils. Scan hanya perangkat yang berhak diuji.

  INSTALASI, PEMBARUAN, DAN VERSI
  - install.sh memasang core atau komponen pilihan: AI Detect, AI Train, AI Chat, Scenario Builder, Offensive dependencies, NEXUS, IoT. ENTER memilih core saja; 'all' memilih semuanya. Perlu Debian/Ubuntu/Kali berbasis apt, internet, dan sudo untuk banyak dependensi.
  - update.sh mengecek internet/server, menampilkan versi/changelog, menawarkan komponen yang belum terpasang, meminta konfirmasi persis YES, mengunduh dan memasang update. Jangan menyarankan menghapus ~/.kecembung sembarangan karena berisi konfigurasi, log, history, hasil, dan data network.
  - Versi repository yang diketahui: ${CURRENT_VERSION:-4.0.0}. Changelog dapat merujuk rilis/fitur berbeda dari file yang terpasang; minta pengguna cek menu dan versi aktual bila ada ketidaksesuaian. Jangan menjamin semua fitur atau dependensi tersedia di setiap instalasi.

  KEAMANAN DAN BATASAN
  - Minta pengguna mengotorisasi hanya perangkat, akun, dan jaringan miliknya atau yang secara eksplisit diizinkan. Untuk pemindaian, sarankan mulai dari localhost/lab/subnet milik sendiri dan rate rendah; jangan ganggu layanan produksi.
  - Jangan meminta password sudo, token ZeroTier, token Telegram, atau kredensial. Sarankan redaksi data sensitif dari output yang dibagikan.
  - Untuk perintah yang mengubah sistem (sudo, firewall, IP, service, file USB, scheduled task, MAC, atau penghapusan), terangkan efeknya dan gunakan backup/konfirmasi yang sesuai. Bedakan perintah diagnosis read-only dari perubahan.
  - Jangan mengklaim dapat menjalankan Kecembung atau melihat mesin pengguna; berikan instruksi agar pengguna menjalankannya dan minta output yang sudah disensor untuk dianalisis.
  "

  session_file="$AI_HISTORY_DIR/chat_$(date +%F_%H-%M-%S).txt"

  echo ""
  echo "[~] Ketik '/exit' untuk keluar"
  echo ""

  CHAT_CONTEXT="$SYSTEM_PROMPT"

  while true; do

    echo "$(date +%s)" > "$WATCHDOG_FILE"

    IFS= read -r -p "You> " prompt

    case "$prompt" in

        /clear)
            CHAT_CONTEXT="$SYSTEM_PROMPT"
            echo "[✔] Context dibersihkan"
            continue
            ;;

        /save)
            echo "$CHAT_CONTEXT" > "$session_file"
            echo "[✔] Session disimpan"
            continue
            ;;

        /help)
            echo ""
            echo "Commands:"
            echo "/clear  = reset memory"
            echo "/save   = save session"
            echo "/help   = bantuan"
            echo "/exit   = keluar"
            echo ""
            continue
            ;;

        /exit)
            break
            ;;

    esac

    [ -z "$prompt" ] && continue

    echo "[USER]" >> "$session_file"
    echo "$prompt" >> "$session_file"
    echo "" >> "$session_file"

    FULL_PROMPT="$CHAT_CONTEXT

    USER:
    $prompt

    AI:
    "

    echo ""
    echo "[~] AI thinking..."
    echo ""

    response=$(printf "%s" "$FULL_PROMPT" | ollama run "$model" 2>/dev/null)

    if [ -z "$response" ]; then
        response="[!] AI tidak memberikan response"
    fi

    CHAT_CONTEXT="$FULL_PROMPT$response

    "

    CHAT_CONTEXT=$(printf "%s" "$CHAT_CONTEXT" | tail -c 16000)

    echo ""
    echo "AI> $response"
    echo ""

    echo "[AI]" >> "$session_file"
    echo "$response" >> "$session_file"
    echo "" >> "$session_file"

  done
}

cmd_ai_download_model() {
  clear

  if ! command -v ollama >/dev/null 2>&1; then
    echo "[!] Ollama belum terinstall"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo "========================="
  echo "  DOWNLOAD AI MODEL"
  echo "========================="
  echo ""

  echo "Example Models:"
  echo "- tinyllama"
  echo "- phi3"
  echo "- gemma:2b"
  echo "- mistral"
  echo ""

  IFS= read -r -p "Model name: " model

  if [ -z "$model" ]; then
    echo "[x] Dibatalkan"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo ""
  echo "[~] Downloading model: $model"
  echo ""

  log_save "Download AI Model: $model"

  ollama pull "$model"

  if [ $? -eq 0 ]; then
    echo ""
    echo "[✔] Model downloaded"
  else
    echo ""
    echo "[!] Failed download model"
  fi

  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

cmd_ai_list_models() {
  clear

  if ! command -v ollama >/dev/null 2>&1; then
    echo "[!] Ollama belum terinstall"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo "========================="
  echo " INSTALLED MODELS"
  echo "========================="
  echo ""

  ollama list

  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

cmd_ai_delete_model() {
  clear

  if ! command -v ollama >/dev/null 2>&1; then
    echo "[!] Ollama belum terinstall"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo "========================="
  echo "  DELETE AI MODEL"
  echo "========================="
  echo ""

  ollama list
  echo ""

  IFS= read -r -p "Model to delete: " model

  if [ -z "$model" ]; then
    echo "[x] Dibatalkan"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  IFS= read -r -p "Type YES to confirm: " confirm

  if [ "$confirm" != "YES" ]; then
    echo "[x] Cancelled"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  log_save "Delete AI Model: $model"

  ollama rm "$model"

  if [ $? -eq 0 ]; then
    echo ""
    echo "[✔] Model deleted"
  else
    echo ""
    echo "[!] Failed delete model"
  fi

  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

cmd_ai_history() {
  clear

  history_dir="$AI_HISTORY_DIR"
  mkdir -p "$history_dir"

  shopt -s nullglob
  mapfile -t files < <(ls -t "$history_dir"/*.txt 2>/dev/null)
  shopt -u nullglob

  echo "========================="
  echo "      AI HISTORY"
  echo "========================="
  echo ""

  if [ ${#files[@]} -eq 0 ]; then
    echo "[!] Tidak ada AI history"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  for i in "${!files[@]}"; do
    echo "$i. $(basename "${files[$i]}")"
  done

  echo ""
  IFS= read -r -p "Pilih file: " pilih

  if [ -z "$pilih" ]; then
    echo "[x] Dibatalkan"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  if ! [[ "$pilih" =~ ^[0-9]+$ ]] || [ -z "${files[$pilih]}" ]; then
    echo "[!] Invalid selection"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo ""
  cat "${files[$pilih]}"

  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

cmd_ai_status() {
  clear

  echo "========================="
  echo "       AI STATUS"
  echo "========================="
  echo ""

  if command -v ollama >/dev/null 2>&1; then
    echo "[✔] Ollama Installed"
  else
    echo "[!] Ollama Not Installed"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  echo ""

  if pgrep ollama >/dev/null 2>&1; then
    echo "[✔] Ollama Service Running"
  else
    echo "[!] Ollama Service Not Running"
  fi

  echo ""
  echo "[~] Installed Models:"
  ollama list

  echo ""
  echo "[~] Memory Usage:"
  free -h

  echo ""
  echo "[~] AI Storage:"
  du -sh "$HOME/.ollama" 2>/dev/null

  echo ""
  echo "[~] Default Model:"
  echo "$AI_MODEL_DEFAULT"

  echo ""
  echo "[~] AI History Size:"
  du -sh "$AI_HISTORY_DIR" 2>/dev/null

  echo ""
  read -p "Tekan ENTER untuk kembali..."
}

cmd_ai_clear_history() {
  clear

  history_dir="$AI_HISTORY_DIR"
  mkdir -p "$history_dir"

  echo "========================="
  echo "  CLEAR AI HISTORY"
  echo "========================="
  echo ""

  IFS= read -r -p "Type YES to clear history: " confirm

  if [ "$confirm" != "YES" ]; then
    echo ""
    echo "[x] Dibatalkan"
    echo ""
    read -p "Tekan ENTER untuk kembali..."
    return
  fi

  find "$history_dir" -type f -name "*.txt" -delete

  echo ""
  echo "[✔] AI history cleared"
  echo ""

  read -p "Tekan ENTER untuk kembali..."
}

# =========================
# 🧠 AI CHAT MENU (entry point sourced by main kecembung script)
# =========================
ai_chat_main() {
            while true; do

              if [ "$RETURN_TO_MAIN" -eq 1 ]; then
                break
              fi

              echo -e "${CYAN}=========================${NC}"
              echo -e "${GREEN}        AI CHAT${NC}"
              echo -e "${CYAN}=========================${NC}"
              echo "1. Start Chat"
              echo "2. Model Manager"
              echo "3. AI History"
              echo "4. AI Status"
              echo "5. Clear History"
              echo "6. Kembali"
              echo -e "${CYAN}=========================${NC}"

              IFS= read -r -p "Pilih menu: " aichat || continue

              case $aichat in
                1) cmd_ai_chat_start ;;

                2)
                  while true; do

                    echo "$(date +%s)" > "$WATCHDOG_FILE"

                    if [ "$RETURN_TO_MAIN" -eq 1 ]; then
                      break
                    fi

                    echo -e "${CYAN}=========================${NC}"
                    echo -e "${GREEN}      MODEL MANAGER${NC}"
                    echo -e "${CYAN}=========================${NC}"
                    echo "1. Download Model"
                    echo "2. List Installed Models"
                    echo "3. Delete Model"
                    echo "4. Kembali"
                    echo -e "${CYAN}=========================${NC}"

                    IFS= read -r -p "Pilih menu: " modelmenu || continue

                    case $modelmenu in
                      1) cmd_ai_download_model ;;
                      2) cmd_ai_list_models ;;
                      3) cmd_ai_delete_model ;;
                      4) break ;;
                      *) echo -e "${RED}Invalid option${NC}" ;;
                    esac

                  done
                  ;;

                3) cmd_ai_history ;;
                4) cmd_ai_status ;;
                5) cmd_ai_clear_history ;;
                6) break ;;
                *) echo -e "${RED}Invalid option${NC}" ;;
              esac

            done
}
