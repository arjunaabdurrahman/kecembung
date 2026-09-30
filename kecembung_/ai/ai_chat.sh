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

  SYSTEM_PROMPT="Kamu adalah KECEMBUNG AI Assistant..

  Tugas kamu:
  - membantu networking
  - membantu Linux
  - membantu troubleshooting
  - menjelaskan hasil scan jaringan
  - membantu beginner memahami output terminal
  - menjawab singkat jelas dan teknikal
  - menjawab dengan bahasa indonesia atau bahasa inggris sesuai pengguna
  - hindari pengunaan **

  Jika ada error:
  - jelaskan penyebab
  - beri solusi bertahap
  - jangan terlalu panjang

  Style:
  - friendly
  - teknikal
  - mudah dipahami beginner

  Nama penciptamu / Adminmu adalah Arjuna Adelio Abdurrahman
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
