from ultralytics import YOLO
import sys
import time
start = time.time()

# argumen: folder dataset
data_path = sys.argv[1] if len(sys.argv) > 1 else "data.yaml"

# load model dasar
model = YOLO("yolov8n.pt")

print(f"[~] Dataset: {data_path}")
print("[~] Training dimulai...")

# training
model.train(
    data=data_path,
    epochs=50,
    imgsz=640,
    device=0
)

end = time.time()
print(f"[✔] Training selesai! Waktu: {int(end-start)} detik")

