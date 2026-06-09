from ultralytics import YOLO
import cv2
import sys
import time
import os

model_path = "yolov8n.pt"
if len(sys.argv) > 4:
    model_path = sys.argv[4]

model = YOLO(model_path)

source = sys.argv[1] if len(sys.argv) > 1 else "0"
save_path = sys.argv[2] if len(sys.argv) > 2 else "./captures"
filter_class = sys.argv[3] if len(sys.argv) > 3 else "all"

os.makedirs(save_path, exist_ok=True)

cap = cv2.VideoCapture(0 if source == "0" else source)

# =========================
# 🖼️ IMAGE MODE
# =========================
if source.endswith(('.jpg', '.png', '.jpeg')):
    frame = cv2.imread(source)
    if frame is None:
        print("❌ Gagal baca image")
        input("ENTER...")
        exit()

    results = model(frame)
    frame = results[0].plot()

    cv2.putText(frame, "Press any key to exit", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0,255,0), 2)

    cv2.imshow("AI IMAGE", frame)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
    exit()

# =========================
# ❌ CEK SOURCE
# =========================
if not cap.isOpened():
    print("❌ Gagal buka sumber video")
    input("Tekan ENTER untuk keluar...")
    exit()

prev_time = 0
mirror = False  # False = normal, True = mirror

# =========================
# 🎥 VIDEO / WEBCAM LOOP
# =========================
while True:
    ret, frame = cap.read()

    if not ret:
        print("❌ Frame gagal dibaca")
        input("Tekan ENTER untuk keluar...")
        break

    if mirror:
        frame = cv2.flip(frame, 1)

    results = model(frame, device=0)

    boxes = results[0].boxes
    names = model.names

    detected = False

    for box in boxes:
        cls = int(box.cls[0])
        label = names[cls]

        if filter_class != "all" and label != filter_class:
            continue

        detected = True

    frame = results[0].plot()

    # =========================
    # 📸 AUTO SAVE
    # =========================
    if detected:
        filename = f"{save_path}/detect_{int(time.time())}.jpg"
        cv2.imwrite(filename, frame)
        print(f"[✔] Saved: {filename}")

    # =========================
    # ⚡ FPS
    # =========================
    curr_time = time.time()
    fps = 1 / (curr_time - prev_time) if prev_time else 0
    prev_time = curr_time

    cv2.putText(frame, f"FPS: {int(fps)}", (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0,255,0), 2)

    # =========================
    # 🧠 INFO EXIT
    # =========================
    cv2.putText(frame, "Press Q or ESC to exit", (10, 60),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,0), 2)

    status = "ON" if mirror else "OFF"
    cv2.putText(frame, f"Mirror: {status} (press M)", (10, 90),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0,255,0), 2)

    cv2.imshow("AI DETECT", frame)

    # =========================
    # 🛑 STOP CONTROL 
    # =========================
    key = cv2.waitKey(1) & 0xFF

    if key == ord('m'):
        mirror = not mirror
        print(f"[~] Mirror: {'ON' if mirror else 'OFF'}")

    if key == ord('q') or key == 27:
        print("[~] Stopping AI...")
        break

cap.release()
cv2.destroyAllWindows()

