# Hướng dẫn train model phân vùng hư hỏng bề mặt (YOLOv8n-seg, 4 lớp)

> Tài liệu bàn giao cho người train model của dự án **Fieldline**. Mục tiêu là đánh giá cơ sở vật chất trong trường học.
> Đọc hết mục 0–2 trước khi tải dữ liệu. Toàn bộ script nằm ở **Phụ lục A**: chép ra thành file `.py` rồi chạy.

---

## 0. Mục tiêu và những thứ cần bàn giao

App chụp một bề mặt (tường, trần, cửa sắt, lan can…). Model phải **tô đúng vùng hư hỏng** (instance segmentation, không phải chỉ khung chữ nhật). Từ mask, app tính diện tích (m²) hoặc chiều dài vết nứt (m), rồi ra chỉ số hư hại và chi phí sửa chữa.

- **Model:** `yolov8n-seg` (Ultralytics), input 640×640, fine-tune từ trọng số COCO có sẵn.
- **Không cần** nhận diện bàn, ghế, máy chiếu, bảng hay tủ điện.

**Danh sách bàn giao** (gom vào một thư mục và nén zip):

| # | File | Ghi chú |
|---|---|---|
| 1 | `best.pt` | Trọng số tốt nhất |
| 2 | `best_float32.tflite` (và `best_float16.tflite` nếu có) | File app dùng |
| 3 | `labels.txt` | 4 dòng, đúng thứ tự ở mục 1 |
| 4 | `check_tflite.txt` | Kết quả `python check_tflite.py best_float32.tflite` (shape input/output) |
| 5 | `data.yaml` và `build_log.txt` | Kết quả in ra của `build_dataset.py` (số ảnh và số polygon mỗi lớp) |
| 6 | Thư mục `runs/segment/<tên>/` | `results.csv`, `results.png`, `MaskPR_curve.png`, `MaskF1_curve.png`, `confusion_matrix_normalized.png`, `args.yaml` |
| 7 | `test_metrics.txt` | Kết quả `yolo segment val … split=test` (mAP từng lớp) |
| 8 | `predict_samples/` | Khoảng 20 ảnh dự đoán trên **ảnh chụp tại trường** |
| 9 | `nguon_du_lieu.md` | Dataset nào, phiên bản/link nào, lấy bao nhiêu ảnh, giấy phép |

---

## 1. Bốn lớp: thứ tự cố định, KHÔNG được đổi

App đọc kết quả theo chỉ số lớp, nên thứ tự phải giữ đúng như sau:

| id | Tên trong `data.yaml` | `labels.txt` (tiếng Việt) | Gán nhãn những gì | KHÔNG gán |
|---|---|---|---|---|
| 0 | `vet_nut` | Vết nứt | Nứt tường, trần, sàn, cột, dầm; nứt chân chim; nứt bậc thang (stair-step) | Mạch vữa, ron gạch, dây điện, vết bút |
| 1 | `tham_moc` | Thấm nước / ẩm mốc | Vệt ố nước, loang ẩm, mốc đen/xanh, vệt muối hoá (trắng) | Bóng đổ, vết bẩn khô |
| 2 | `bong_son` | Bong tróc sơn | Sơn phồng, sơn bong mảng, lớp vữa lộ ra dưới sơn | Tường chưa sơn (thiết kế) |
| 3 | `gi_set` | Gỉ sét | Gỉ trên cửa sắt, lan can, khung cửa sổ, thép lộ | Sơn màu nâu đỏ còn nguyên |

Ghi chú:
- Vùng vừa thấm vừa bong sơn: vẽ **hai polygon** riêng, được phép chồng lên nhau.
- Tên dùng ASCII trong `data.yaml` để tránh lỗi font. File `labels.txt` gửi cho app thì dùng cột tiếng Việt:

```text
Vết nứt
Thấm nước / ẩm mốc
Bong tróc sơn
Gỉ sét
```

---

## 2. Nguồn dữ liệu

### 2.1 Dataset ngoài

Các bộ có **mask ngữ nghĩa** (ảnh mask PNG) chuyển bằng `mask_to_yolo.py`. Các bộ Roboflow đã ở dạng polygon thì chuyển bằng `remap_yolo.py`.

| Lớp | Dataset | Định dạng | Giấy phép | Lấy tối đa | Ghi chú |
|---|---|---|---|---|---|
| vet_nut | **CrackSeg9k**: [bài báo](https://arxiv.org/abs/2208.13054), bản gốc trên Harvard Dataverse, bản sao trên [Roboflow](https://universe.roboflow.com/cfd/crackseg9k-6laab) | Mask nhị phân | Kiểm tra trên trang Dataverse (bản Roboflow ghi CC BY 4.0) | 1.500 | Gộp từ nhiều bộ, có cả mặt đường. Đã có báo cáo một số ảnh lệch mask, **phải chạy preview** |
| vet_nut | **DeepCrack**: [github.com/yhlleo/DeepCrack](https://github.com/yhlleo/DeepCrack) | Mask nhị phân (`train_img/`, `train_lab/`, `test_img/`, `test_lab/`), 537 ảnh | Chỉ cho nghiên cứu, giáo dục phi thương mại (dùng cho đồ án được) | Lấy hết | Ảnh bê tông, chất lượng nhãn tốt |
| gi_set | **Corrosion Condition State Semantic Segmentation**, Virginia Tech: [DOI 10.7294/16624663](https://data.lib.vt.edu/articles/dataset/Corrosion_Condition_State_Semantic_Segmentation_Dataset/16624663) | Mask theo màu, 4 mức (good/fair/poor/severe), 440 ảnh | Xem trang dataset, **bắt buộc trích dẫn** | Lấy hết | Ảnh cầu thép. Gộp mọi mức có gỉ thành `gi_set` (xem 4.3) |
| gi_set | Roboflow **rust** ([rust-jgaoo/rust-ytsho](https://universe.roboflow.com/rust-jgaoo/rust-ytsho), khoảng 10k ảnh, CC BY 4.0) hoặc [Corrosion Instance Segmentation](https://universe.roboflow.com/failure-sjoo6/corrosion-instance-segmentation-sfcpc-1yuxj) (CC BY 4.0) | Polygon | CC BY 4.0 | 1.500 | Chọn một bộ chính, bộ kia bổ sung |
| tham_moc, bong_son, vet_nut | Roboflow **Building defect on walls** ([builddef2](https://universe.roboflow.com/builddef2/building-defect-on-walls)): crack, mold, peeling_paint, stairstep_crack, water_seepage | **Cần kiểm tra** có polygon không | Xem trang | Lấy hết | Gần với tường trường học nhất |
| tham_moc, vet_nut, gi_set | Roboflow **structural-condition-segmentation** ([projturi](https://universe.roboflow.com/projturi/structural-condition-segmentation-avgxh)), khoảng 7,7k ảnh, crack/corrosion/mold | Instance segmentation | Xem trang | mold: hết; crack và corrosion: theo hạn mức | Nguồn chính cho `tham_moc` |
| bong_son | Roboflow [paint_peel](https://universe.roboflow.com/crack-sk4ke/paint_peel), [Peeling Paint Project](https://universe.roboflow.com/fardas-workspace/peeling-paint-project) | paint_peel là instance seg; bộ kia cần kiểm tra | CC BY 4.0 | Lấy hết | |

**Trước khi tải bất kỳ bộ Roboflow nào**, mở trang của nó và kiểm tra:
1. **Project Type** phải là *Instance Segmentation*. Nếu là *Object Detection* thì chỉ có bbox, không dùng được (script sẽ báo "bỏ N dòng chỉ có bbox").
2. Số ảnh thực tế và tên lớp. Ghi lại vào `nguon_du_lieu.md`.
3. Giấy phép.

Cũng có thể tìm thêm trên Roboflow Universe với từ khoá `wall mold segmentation`, `water stain segmentation`, `peeling paint segmentation`, `rust segmentation`. Nhớ lọc theo *Instance Segmentation*.

**Cách tải từ Roboflow:** tạo tài khoản miễn phí, mở dataset, bấm *Download Dataset*, chọn format **YOLOv8** rồi *Download zip*. Có thể dùng mã Python Roboflow đưa ra (cần API key của chính người train, **không commit key vào repo**).

### 2.2 Ảnh chụp tại trường (bắt buộc cho tập test)

Dữ liệu ngoài chủ yếu là cầu và mặt đường, khác với tường lớp học. Vì vậy **số liệu đánh giá báo cáo cho hội đồng phải lấy từ ảnh chụp tại trường.**

- **Số lượng:** 200–300 ảnh, cố gắng mỗi lớp có ít nhất 40 ảnh. Thêm khoảng 30 ảnh **tường sạch, không hư hỏng** để làm ảnh nền (giúp model bớt báo nhầm).
- **Cách chụp:** thẳng góc với bề mặt, cách khoảng 1–2 m, đủ sáng, không bật flash sát tường. Chụp bằng điện thoại, để nguyên độ phân giải.
- **Gán nhãn:** tạo project Roboflow loại *Instance Segmentation*, dùng công cụ **Smart Polygon (SAM)**: bấm vào vùng là tự ra polygon, sửa lại nếu cần. Đặt tên lớp **đúng** `vet_nut`, `tham_moc`, `bong_son`, `gi_set`. Ảnh tường sạch để trống, không vẽ gì.
- **Xuất:** format YOLOv8. Khi tạo version, **không** bật augmentation hay resize trên Roboflow. Sau đó chạy `remap_yolo.py` với ánh xạ giữ nguyên tên (mục 4.4).

> Nếu chưa có ảnh trường thì vẫn train được. `build_dataset.py` tự tách 5% dữ liệu ngoài làm test tạm. Khi có ảnh trường, build lại dataset rồi fine-tune thêm (mục 7.3).

---

## 3. Môi trường

Khuyến nghị **Kaggle Notebook** (GPU T4/P100, khoảng 30 giờ/tuần miễn phí) hoặc **Google Colab** (GPU T4). Nên làm cả việc chuẩn bị dữ liệu và train trên cùng một máy, vì `data.yaml` lưu đường dẫn tuyệt đối.

```bash
pip install -U ultralytics opencv-python-headless pyyaml
# chỉ cần khi kiểm tra file tflite:
pip install ai-edge-litert
```

Cấu trúc thư mục làm việc:

```text
work/
├── scripts/      # các file .py ở Phụ lục A (common.py phải nằm cùng thư mục)
├── raw/          # dataset tải về, giải nén nguyên trạng
├── interim/      # mỗi nguồn sau khi chuyển: interim/<nguồn>/{images,labels}
└── dataset/      # dataset cuối cùng do build_dataset.py tạo
```

Các lệnh bên dưới chạy trong `work/scripts/`.

---

## 4. Chuyển từng nguồn sang YOLO-seg

Định dạng nhãn YOLO-seg: mỗi dòng là `class x1 y1 x2 y2 …`, toạ độ chuẩn hoá về 0–1. Ảnh không có dòng nào là ảnh nền.

**Quy trình chung cho mọi bộ mask:**
1. Chạy `--inspect` trước để xem mask gồm những giá trị pixel nào.
2. Sau đó mới chạy chuyển đổi.
3. Chạy `preview_labels.py` và **xem bằng mắt** khoảng 30 ảnh.

Tên thư mục bên dưới là ví dụ. Sau khi giải nén, xem tên thật bằng `ls` rồi sửa lại cho đúng.

### 4.1 DeepCrack → `vet_nut`

```bash
python mask_to_yolo.py --images ../raw/DeepCrack/train_img --masks ../raw/DeepCrack/train_lab --inspect
python mask_to_yolo.py --images ../raw/DeepCrack/train_img --masks ../raw/DeepCrack/train_lab \
    --out ../interim/deepcrack_train --class-id 0 --threshold 128 --dilate 1
python mask_to_yolo.py --images ../raw/DeepCrack/test_img --masks ../raw/DeepCrack/test_lab \
    --out ../interim/deepcrack_test --class-id 0 --threshold 128 --dilate 1
python preview_labels.py --dir ../interim/deepcrack_train --n 30 --out ../preview/deepcrack
```

`--dilate 1` nới vết nứt thêm 1 pixel, để nét nứt mảnh không bị đứt khi model thu mask về 160×160.

### 4.2 CrackSeg9k → `vet_nut`

```bash
python mask_to_yolo.py --images ../raw/crackseg9k/Images --masks ../raw/crackseg9k/Masks --inspect
python mask_to_yolo.py --images ../raw/crackseg9k/Images --masks ../raw/crackseg9k/Masks \
    --out ../interim/crackseg9k --class-id 0 --threshold 128 --dilate 1
python preview_labels.py --dir ../interim/crackseg9k --n 50 --out ../preview/crackseg9k
```

- Nếu `--inspect` cho thấy mask là 0/1 thay vì 0/255, dùng `--threshold 1`.
- Nếu script báo nhiều "ảnh thiếu mask", nghĩa là tên file ảnh và mask không khớp. Xem tên thật, sửa hàm `find_mask` hoặc đổi tên file.
- Nếu dùng bản Roboflow của CrackSeg9k (đã là polygon) thì bỏ qua mục này và dùng `remap_yolo.py`.

### 4.3 Corrosion Condition State (Virginia Tech) → `gi_set`

Mask tô theo màu và mức độ. Chạy `--inspect` để biết giá trị xám của từng mức:

```bash
python mask_to_yolo.py --images ../raw/corrosion_vt/Train/images --masks ../raw/corrosion_vt/Train/masks --inspect
```

- Giá trị chiếm nhiều pixel nhất thường là **nền** (background).
- Mở vài mask cạnh ảnh gốc để xác định giá trị nào ứng với *fair*, *poor*, *severe*.
- Đưa **các giá trị có gỉ** vào `--values`. Không đưa nền vào. Với mức *good*, nếu mask có tô thì cũng không đưa vào.

```bash
# Ví dụ: giả sử inspect ra 0 (nền), 38, 75, 113. Thay bằng số thật.
python mask_to_yolo.py --images ../raw/corrosion_vt/Train/images --masks ../raw/corrosion_vt/Train/masks \
    --out ../interim/corrosion_vt --class-id 3 --values 38 75 113 --min-area 80
python preview_labels.py --dir ../interim/corrosion_vt --n 30 --out ../preview/corrosion_vt
```

### 4.4 Các bộ Roboflow (đã là polygon) → gộp lớp

Xem tên lớp gốc trước:

```bash
cat ../raw/rf_wall_defect/data.yaml
```

Sau đó ánh xạ sang lớp của dự án. Tên bên trái phải **giống hệt** trong `data.yaml`; lớp nào không liệt kê sẽ bị bỏ.

```bash
# Building defect on walls
python remap_yolo.py --src ../raw/rf_wall_defect --out ../interim/rf_wall_defect \
    --map crack=vet_nut stairstep_crack=vet_nut mold=tham_moc water_seepage=tham_moc peeling_paint=bong_son

# structural-condition-segmentation
python remap_yolo.py --src ../raw/rf_structural --out ../interim/rf_structural \
    --map crack=vet_nut mold=tham_moc corrosion=gi_set

# Rust
python remap_yolo.py --src ../raw/rf_rust --out ../interim/rf_rust --map rust=gi_set

# Bong sơn
python remap_yolo.py --src ../raw/rf_paint_peel --out ../interim/rf_paint_peel --map paint_peel=bong_son

# Ảnh chụp tại trường (đã đặt đúng tên lớp)
python remap_yolo.py --src ../raw/school --out ../interim/school \
    --map vet_nut=vet_nut tham_moc=tham_moc bong_son=bong_son gi_set=gi_set
```

Sau mỗi lệnh, chạy `preview_labels.py --dir ../interim/<nguồn>` và kiểm tra bằng mắt.

---

## 5. Gộp và cân bằng dataset

Vết nứt có rất nhiều dữ liệu, thấm/mốc và bong sơn thì ít. Nếu không giới hạn, model sẽ thiên về vết nứt; đây đúng là lỗi của model cũ (thiên về một lớp). Dùng `:<số>` sau mỗi nguồn để đặt trần số ảnh.

**Mục tiêu:**
- Mỗi lớp có khoảng **1.500–2.500 polygon** trong train.
- Lớp ít nhất không dưới một nửa lớp nhiều nhất.
- Ảnh nền chiếm khoảng 10%.

```bash
python build_dataset.py --out ../dataset \
    --source ../interim/deepcrack_train \
    --source ../interim/crackseg9k:1200 \
    --source ../interim/corrosion_vt \
    --source ../interim/rf_rust:1200 \
    --source ../interim/rf_wall_defect \
    --source ../interim/rf_structural:2500 \
    --source ../interim/rf_paint_peel \
    --school ../interim/school --school-train 0.4 \
    | tee ../build_log.txt
```

- Đọc bảng thống kê ở cuối `build_log.txt`. Lớp nào quá nhiều thì giảm hạn mức của nguồn tương ứng rồi chạy lại. Mỗi lần chạy, script **xoá và tạo lại** `../dataset`.
- Có `--school`: 40% ảnh trường vào train, 60% làm **test**. Dữ liệu ngoài chia train/val 90/10.
- Chưa có ảnh trường: bỏ `--school`, script tách 5% dữ liệu ngoài làm test tạm.

Kiểm tra lần cuối:

```bash
python preview_labels.py --dir ../dataset --split train --n 40 --out ../preview/final_train
```

---

## 6. Kiểm tra nhanh trước khi train dài

Chạy thử 3 epoch để chắc dữ liệu đọc được:

```bash
yolo segment train model=yolov8n-seg.pt data=../dataset/data.yaml imgsz=640 epochs=3 batch=16 name=smoke
```

Đọc log Ultralytics, dòng `train: Scanning ... N images, M backgrounds, 0 corrupt`:
- **M quá lớn** (gần bằng N): nhãn không được đọc. Kiểm tra lại tên file ảnh và nhãn có trùng nhau không.
- **Có ảnh `corrupt`**: xoá các ảnh đó rồi build lại.

---

## 7. Train

### 7.1 Lệnh train chính

```bash
yolo segment train \
    model=yolov8n-seg.pt data=../dataset/data.yaml \
    imgsz=640 epochs=120 patience=25 batch=16 \
    optimizer=auto cos_lr=True close_mosaic=10 \
    degrees=5 fliplr=0.5 flipud=0.0 \
    name=surface_v1 seed=0
```

- `yolov8n-seg.pt` được tải tự động; đây là trọng số COCO dùng làm điểm xuất phát.
- `flipud=0.0`: tường và trần có hướng tự nhiên, không lật dọc ảnh.
- Nếu GPU báo hết bộ nhớ (OOM) thì giảm `batch=8`.
- Trên T4, thời gian ước tính khoảng 2–5 giờ tuỳ số ảnh. Với Colab, nên lưu `runs/` vào Google Drive (`project=/content/drive/MyDrive/fieldline_runs`) để không mất kết quả khi phiên bị ngắt.
- Train bị ngắt thì chạy tiếp bằng `yolo segment train resume model=<…>/weights/last.pt`.

### 7.2 Theo dõi

- Xem `results.png`: `val/seg_loss` phải giảm, `metrics/mAP50(M)` phải tăng. Chữ **(M)** là chỉ số theo mask, đây là chỉ số cần quan tâm. **(B)** là chỉ số theo box.
- Nếu `train` loss giảm mà `val` tăng từ sớm (overfit), hãy thêm dữ liệu, hoặc tăng augmentation (`scale=0.5`, `hsv_v=0.5`).

### 7.3 Fine-tune thêm khi có ảnh trường (nếu lần đầu train khi chưa có)

```bash
# build lại dataset có --school (mục 5), rồi:
yolo segment train model=runs/segment/surface_v1/weights/best.pt data=../dataset/data.yaml \
    imgsz=640 epochs=40 lr0=0.002 warmup_epochs=1 close_mosaic=5 name=surface_v1_school
```

---

## 8. Đánh giá

```bash
# Chỉ số trên tập test (ảnh trường nếu có)
yolo segment val model=runs/segment/surface_v1/weights/best.pt data=../dataset/data.yaml \
    split=test imgsz=640 | tee ../test_metrics.txt

# Ảnh dự đoán minh hoạ
yolo segment predict model=runs/segment/surface_v1/weights/best.pt \
    source=../dataset/images/test conf=0.25 save=True name=predict_test
```

Trong `test_metrics.txt`, ghi lại **mAP50(M)** và **mAP50-95(M)** của từng lớp.

**Ngưỡng tin cậy cho app:** xem `MaskF1_curve.png`, lấy với mỗi lớp mức `conf` mà F1 đạt đỉnh. Ghi 4 con số này vào `test_metrics.txt` để người làm app đưa vào `AiConfig`.

**Lỗi cần ghi chú cho người làm app:** xem `confusion_matrix_normalized.png` và các ảnh trong `predict_test`, rồi ghi lại các nhầm lẫn thường gặp. Ví dụ: mạch gạch bị báo thành vết nứt, bóng tối bị báo thành thấm.

---

## 9. Xuất TFLite

```bash
yolo export model=runs/segment/surface_v1/weights/best.pt format=tflite imgsz=640
# -> runs/segment/surface_v1/weights/best_saved_model/best_float32.tflite (và best_float16.tflite)

python check_tflite.py runs/segment/surface_v1/weights/best_saved_model/best_float32.tflite | tee ../check_tflite.txt
```

**Dự kiến** ra một input và hai output:

| Tensor | Shape dự kiến | Ý nghĩa |
|---|---|---|
| input | `[1, 640, 640, 3]` float32 (NHWC, RGB, 0–1) | Ảnh đầu vào |
| output 0 | `[1, 40, 8400]` | 4 số của box + 4 điểm lớp + 32 hệ số mask |
| output 1 | `[1, 160, 160, 32]` | 32 mask gốc (prototype) |

- Thứ tự hai output và chiều của từng output có thể khác. **Ghi đúng kết quả thật** trong `check_tflite.txt`, vì app sẽ viết code theo file này.
- Model cũ của app dùng input NCHW `[1, 3, 640, 640]`. Nếu bản xuất ra là NHWC thì cứ giữ nguyên, phía app sẽ tự sửa.
- **Không** xuất INT8 nếu không được yêu cầu.

---

## 10. Lỗi thường gặp

| Hiện tượng | Nguyên nhân / cách sửa |
|---|---|
| `mask_to_yolo` báo nhiều "ảnh thiếu mask" | Tên mask khác tên ảnh (ví dụ `abc.jpg` và `abc_mask.png`). Hàm `find_mask` đã thử `_mask`, `_label`, `_gt`; nếu khác nữa thì thêm vào hàm |
| Preview tô kín cả ảnh | Mask bị đảo (nền trắng). Dùng `--values 0` hoặc xem lại `--inspect` |
| Vết nứt trên preview bị đứt thành nhiều mẩu | Tăng `--dilate 2`, giảm `--min-area` |
| Có nhiều mẩu polygon li ti | Tăng `--min-area` (ví dụ 100–200 với ảnh lớn) |
| `remap_yolo` báo "bỏ N dòng chỉ có bbox" với N lớn | Dataset là Object Detection. Bỏ bộ đó, hoặc chọn lại format khi export |
| Ultralytics báo nhiều `backgrounds` bất thường | Nhãn rỗng do ánh xạ sai tên lớp. Xem dòng `Ánh xạ:` do `remap_yolo` in ra |
| mAP của một lớp gần 0 | Lớp quá ít dữ liệu hoặc nhãn sai. Đếm lại trong `build_log.txt` và xem preview |

---

## 11. Giấy phép và trích dẫn

Ghi vào `nguon_du_lieu.md` và vào báo cáo:
- **CrackSeg9k:** Kulkarni et al., *CrackSeg9k: A Collection and Benchmark for Crack Segmentation Datasets and Frameworks*, 2022 (arXiv:2208.13054).
- **DeepCrack:** Liu et al., *DeepCrack: A deep hierarchical feature learning architecture for crack segmentation*, Neurocomputing 2019. Chỉ dùng cho nghiên cứu, giáo dục.
- **Corrosion Condition State:** Bianchi, E. & Hebdon, M. (2021), *Corrosion Condition State Semantic Segmentation Dataset*, Virginia Tech, DOI 10.7294/16624663.
- **Các bộ Roboflow:** ghi tên project, workspace, phiên bản (version) và giấy phép như trên trang.

---

## Phụ lục A: Script

Tạo thư mục `scripts/` và chép từng khối dưới đây thành file cùng tên. Các script đã được chạy thử trên Python 3.9 với `opencv-python-headless`, `numpy`, `pyyaml`.

### `common.py`

```python
"""Cấu hình chung: thứ tự lớp CỐ ĐỊNH, app Flutter đọc theo đúng thứ tự này."""
CLASSES = ["vet_nut", "tham_moc", "bong_son", "gi_set"]
CLASSES_VI = ["Vết nứt", "Thấm nước / ẩm mốc", "Bong tróc sơn", "Gỉ sét"]
IMG_EXTS = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
```

### `mask_to_yolo.py`

```python
"""Chuyển dataset mask ngữ nghĩa (ảnh + mask PNG) sang nhãn YOLO-seg (polygon).

Dùng cho CrackSeg9k, DeepCrack, Corrosion Condition State (Virginia Tech)...

Ví dụ:
  # Xem trước mask có những giá trị pixel nào
  python mask_to_yolo.py --images raw/deepcrack/train_img --masks raw/deepcrack/train_lab --inspect

  # Chuyển: mọi pixel có giá trị >= 128 là vết nứt (lớp 0)
  python mask_to_yolo.py --images raw/deepcrack/train_img --masks raw/deepcrack/train_lab \
      --out interim/deepcrack --class-id 0 --threshold 128
"""
import argparse
import shutil
from pathlib import Path

import cv2
import numpy as np

from common import CLASSES, IMG_EXTS


def find_mask(mask_dir: Path, stem: str):
    for ext in (".png", ".bmp", ".jpg", ".tif", ".tiff"):
        for name in (stem, stem + "_mask", stem + "_label", stem + "_gt"):
            p = mask_dir / (name + ext)
            if p.exists():
                return p
    return None


def load_gray(path: Path):
    m = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if m is None:
        return None
    if m.ndim == 3:
        m = cv2.cvtColor(m[:, :, :3], cv2.COLOR_BGR2GRAY)
    return m


def mask_to_polygons(binary, min_area, epsilon_frac):
    h, w = binary.shape
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    polys = []
    for c in contours:
        if cv2.contourArea(c) < min_area:
            continue
        eps = epsilon_frac * cv2.arcLength(c, True)
        c = cv2.approxPolyDP(c, eps, True)
        if len(c) < 3:
            continue
        pts = c.reshape(-1, 2).astype(np.float32)
        pts[:, 0] /= w
        pts[:, 1] /= h
        polys.append(np.clip(pts, 0, 1))
    return polys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--images", required=True, type=Path)
    ap.add_argument("--masks", required=True, type=Path)
    ap.add_argument("--out", type=Path, help="Thư mục ra: <out>/images, <out>/labels")
    ap.add_argument("--class-id", type=int, help="0=vet_nut 1=tham_moc 2=bong_son 3=gi_set")
    ap.add_argument("--threshold", type=int, default=128,
                    help="Pixel >= ngưỡng là vùng hư hỏng (mask nhị phân)")
    ap.add_argument("--values", type=int, nargs="*",
                    help="Thay cho --threshold: danh sách giá trị pixel tính là hư hỏng")
    ap.add_argument("--min-area", type=float, default=30, help="Bỏ vùng nhỏ hơn (pixel²)")
    ap.add_argument("--epsilon", type=float, default=0.002,
                    help="Mức đơn giản hoá polygon (tỉ lệ chu vi); vết nứt nên để nhỏ")
    ap.add_argument("--dilate", type=int, default=0,
                    help="Nới mask N pixel trước khi lấy viền (giúp vết nứt mảnh không bị đứt)")
    ap.add_argument("--inspect", action="store_true", help="Chỉ in các giá trị pixel trong 20 mask đầu")
    args = ap.parse_args()

    images = sorted(p for p in args.images.iterdir() if p.suffix.lower() in IMG_EXTS)
    if args.inspect:
        seen = {}
        for img in images[:20]:
            mp = find_mask(args.masks, img.stem)
            if mp is None:
                continue
            vals, counts = np.unique(load_gray(mp), return_counts=True)
            for v, c in zip(vals.tolist(), counts.tolist()):
                seen[v] = seen.get(v, 0) + c
        print("Giá trị pixel : số pixel (20 mask đầu)")
        for v in sorted(seen):
            print(f"  {v:>4} : {seen[v]}")
        return

    if args.out is None or args.class_id is None:
        ap.error("--out và --class-id là bắt buộc khi chuyển đổi")
    if not 0 <= args.class_id < len(CLASSES):
        ap.error(f"--class-id phải trong 0..{len(CLASSES) - 1}")

    (args.out / "images").mkdir(parents=True, exist_ok=True)
    (args.out / "labels").mkdir(parents=True, exist_ok=True)
    n_ok = n_empty = n_missing = n_poly = 0
    kernel = None
    if args.dilate > 0:
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * args.dilate + 1,) * 2)

    for img in images:
        mp = find_mask(args.masks, img.stem)
        if mp is None:
            n_missing += 1
            continue
        m = load_gray(mp)
        im = cv2.imread(str(img))
        if m is None or im is None:
            n_missing += 1
            continue
        if m.shape[:2] != im.shape[:2]:
            m = cv2.resize(m, (im.shape[1], im.shape[0]), interpolation=cv2.INTER_NEAREST)
        if args.values:
            binary = np.isin(m, args.values).astype(np.uint8) * 255
        else:
            binary = (m >= args.threshold).astype(np.uint8) * 255
        if kernel is not None:
            binary = cv2.dilate(binary, kernel)
        polys = mask_to_polygons(binary, args.min_area, args.epsilon)
        lines = [
            f"{args.class_id} " + " ".join(f"{x:.6f} {y:.6f}" for x, y in p) for p in polys
        ]
        shutil.copy2(img, args.out / "images" / img.name)
        (args.out / "labels" / (img.stem + ".txt")).write_text("\n".join(lines))
        n_poly += len(polys)
        if polys:
            n_ok += 1
        else:
            n_empty += 1

    print(f"Xong: {n_ok} ảnh có nhãn, {n_empty} ảnh không có vùng hư hỏng (ảnh nền), "
          f"{n_missing} ảnh thiếu mask, tổng {n_poly} polygon -> {args.out}")


if __name__ == "__main__":
    main()
```

### `remap_yolo.py`

```python
"""Gộp/đổi tên lớp của dataset đã ở định dạng YOLO-seg (ví dụ tải từ Roboflow
chọn "YOLOv8" + Instance Segmentation) về 4 lớp của dự án.

Ví dụ:
  python remap_yolo.py --src raw/rf_wall_defect --out interim/rf_wall_defect \
      --map "crack=vet_nut" "stairstep_crack=vet_nut" "mold=tham_moc" \
            "water_seepage=tham_moc" "peeling_paint=bong_son"

Lớp nào không có trong --map sẽ bị bỏ. Dòng nhãn chỉ có bbox (5 số) cũng bị bỏ,
vì model segmentation cần polygon.
"""
import argparse
import shutil
from pathlib import Path

import yaml

from common import CLASSES, IMG_EXTS


def load_names(src: Path):
    data = yaml.safe_load((src / "data.yaml").read_text())
    names = data["names"]
    if isinstance(names, dict):
        names = [names[k] for k in sorted(names)]
    return [str(n) for n in names]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, type=Path, help="Thư mục có data.yaml")
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--map", nargs="+", required=True, help="ten_lop_goc=ten_lop_moi")
    args = ap.parse_args()

    names = load_names(args.src)
    mapping = {}
    for item in args.map:
        old, new = item.split("=", 1)
        if new not in CLASSES:
            ap.error(f"'{new}' không thuộc {CLASSES}")
        if old not in names:
            print(f"[cảnh báo] lớp '{old}' không có trong data.yaml: {names}")
            continue
        mapping[names.index(old)] = CLASSES.index(new)
    print("Ánh xạ:", {names[k]: CLASSES[v] for k, v in mapping.items()})

    (args.out / "images").mkdir(parents=True, exist_ok=True)
    (args.out / "labels").mkdir(parents=True, exist_ok=True)
    kept = dropped_cls = dropped_bbox = n_img = 0
    for lbl in args.src.rglob("labels/*.txt"):
        img_dir = lbl.parent.parent / "images"
        img = next((img_dir / (lbl.stem + e) for e in IMG_EXTS
                    if (img_dir / (lbl.stem + e)).exists()), None)
        if img is None:
            continue
        out_lines = []
        for line in lbl.read_text().splitlines():
            parts = line.split()
            if not parts:
                continue
            cls = int(parts[0])
            if len(parts) < 7 or (len(parts) - 1) % 2:
                dropped_bbox += 1
                continue
            if cls not in mapping:
                dropped_cls += 1
                continue
            out_lines.append(" ".join([str(mapping[cls])] + parts[1:]))
            kept += 1
        # Giữ cả ảnh không còn nhãn: làm ảnh nền (giảm báo nhầm)
        name = f"{lbl.parent.parent.name}_{img.name}"
        shutil.copy2(img, args.out / "images" / name)
        (args.out / "labels" / (Path(name).stem + ".txt")).write_text("\n".join(out_lines))
        n_img += 1
    print(f"Xong: {n_img} ảnh, giữ {kept} polygon, bỏ {dropped_cls} (lớp không dùng), "
          f"bỏ {dropped_bbox} (chỉ có bbox) -> {args.out}")


if __name__ == "__main__":
    main()
```

### `build_dataset.py`

```python
"""Gộp các nguồn trong interim/ thành dataset cuối cùng + data.yaml.

- Mỗi nguồn được giới hạn số ảnh (--cap) để cân bằng lớp.
- Ảnh không có nhãn (ảnh nền) bị giới hạn theo --bg-ratio.
- Ảnh chụp tại trường (--school) KHÔNG trộn ngẫu nhiên: một phần vào train,
  phần còn lại làm tập test riêng.

Ví dụ:
  python build_dataset.py --out dataset \
      --source interim/crackseg9k:1500 --source interim/deepcrack:300 \
      --source interim/rf_wall_defect --source interim/rf_rust:1500 \
      --school interim/school --school-train 0.4
"""
import argparse
import random
import shutil
from collections import Counter
from pathlib import Path

import yaml

from common import CLASSES, IMG_EXTS


def collect(src: Path):
    items = []
    for img in sorted((src / "images").iterdir()):
        if img.suffix.lower() not in IMG_EXTS:
            continue
        lbl = src / "labels" / (img.stem + ".txt")
        classes = []
        if lbl.exists():
            classes = [int(l.split()[0]) for l in lbl.read_text().splitlines() if l.strip()]
        items.append((img, lbl, classes))
    return items


def copy(items, out: Path, split: str, prefix: str, counter: Counter):
    (out / "images" / split).mkdir(parents=True, exist_ok=True)
    (out / "labels" / split).mkdir(parents=True, exist_ok=True)
    for img, lbl, classes in items:
        name = f"{prefix}__{img.stem}"
        shutil.copy2(img, out / "images" / split / (name + img.suffix.lower()))
        dst = out / "labels" / split / (name + ".txt")
        if lbl.exists():
            shutil.copy2(lbl, dst)
        else:
            dst.write_text("")
        counter[(split, "ảnh")] += 1
        if not classes:
            counter[(split, "ảnh nền")] += 1
        for c in classes:
            counter[(split, CLASSES[c])] += 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--source", action="append", default=[],
                    help="thu_muc[:so_anh_toi_da] (lặp lại cho nhiều nguồn)")
    ap.add_argument("--school", type=Path, help="Ảnh chụp tại trường đã gán nhãn")
    ap.add_argument("--school-train", type=float, default=0.4,
                    help="Tỉ lệ ảnh trường đưa vào train, phần còn lại là test")
    ap.add_argument("--val", type=float, default=0.1, help="Tỉ lệ val của dữ liệu ngoài")
    ap.add_argument("--test-external", type=float, default=0.05,
                    help="Tỉ lệ test từ dữ liệu ngoài (dùng khi chưa có ảnh trường)")
    ap.add_argument("--bg-ratio", type=float, default=0.1,
                    help="Ảnh nền tối đa so với ảnh có nhãn")
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    rng = random.Random(args.seed)
    if args.out.exists():
        shutil.rmtree(args.out)
    counter = Counter()

    for spec in args.source:
        path, _, cap = spec.partition(":")
        src = Path(path)
        items = collect(src)
        labeled = [i for i in items if i[2]]
        background = [i for i in items if not i[2]]
        rng.shuffle(labeled)
        rng.shuffle(background)
        if cap:
            labeled = labeled[: int(cap)]
        background = background[: int(len(labeled) * args.bg_ratio)]
        chosen = labeled + background
        rng.shuffle(chosen)
        n = len(chosen)
        n_test = int(n * args.test_external) if not args.school else 0
        n_val = int(n * args.val)
        copy(chosen[:n_test], args.out, "test", src.name, counter)
        copy(chosen[n_test:n_test + n_val], args.out, "val", src.name, counter)
        copy(chosen[n_test + n_val:], args.out, "train", src.name, counter)
        print(f"{src.name}: {len(labeled)} ảnh có nhãn + {len(background)} ảnh nền")

    if args.school:
        items = collect(args.school)
        rng.shuffle(items)
        k = int(len(items) * args.school_train)
        copy(items[:k], args.out, "train", "school", counter)
        copy(items[k:], args.out, "test", "school", counter)
        print(f"school: {k} ảnh vào train, {len(items) - k} ảnh vào test")

    data = {
        "path": str(args.out.resolve()),
        "train": "images/train",
        "val": "images/val",
        "names": {i: n for i, n in enumerate(CLASSES)},
    }
    if (args.out / "images" / "test").exists():
        data["test"] = "images/test"
    (args.out / "data.yaml").write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False))

    print("\nThống kê (số ảnh / số polygon mỗi lớp):")
    for split in ("train", "val", "test"):
        row = [f"{k}={counter[(split, k)]}" for k in ["ảnh", "ảnh nền", *CLASSES]]
        print(f"  {split:5}: " + ", ".join(row))
    print(f"\n-> {args.out / 'data.yaml'}")


if __name__ == "__main__":
    main()
```

### `preview_labels.py`

```python
"""Vẽ polygon lên ảnh để kiểm tra bằng mắt sau khi chuyển đổi.

  python preview_labels.py --dir dataset --split train --n 30 --out preview
"""
import argparse
import random
from pathlib import Path

import cv2
import numpy as np

from common import CLASSES, IMG_EXTS

COLORS = [(0, 0, 255), (255, 128, 0), (0, 200, 255), (0, 128, 128)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True, type=Path, help="Thư mục dataset hoặc interim/<nguồn>")
    ap.add_argument("--split", default="", help="train/val/test (bỏ trống với thư mục interim)")
    ap.add_argument("--n", type=int, default=30)
    ap.add_argument("--out", type=Path, default=Path("preview"))
    args = ap.parse_args()

    img_dir = args.dir / "images" / args.split
    lbl_dir = args.dir / "labels" / args.split
    imgs = [p for p in img_dir.iterdir() if p.suffix.lower() in IMG_EXTS]
    random.seed(0)
    random.shuffle(imgs)
    args.out.mkdir(parents=True, exist_ok=True)
    for img_path in imgs[: args.n]:
        im = cv2.imread(str(img_path))
        h, w = im.shape[:2]
        overlay = im.copy()
        lbl = lbl_dir / (img_path.stem + ".txt")
        for line in (lbl.read_text().splitlines() if lbl.exists() else []):
            parts = line.split()
            if len(parts) < 7:
                continue
            c = int(parts[0])
            pts = (np.array(parts[1:], dtype=np.float32).reshape(-1, 2) * [w, h]).astype(np.int32)
            cv2.fillPoly(overlay, [pts], COLORS[c])
            cv2.polylines(im, [pts], True, COLORS[c], 2)
            cv2.putText(im, CLASSES[c], tuple(pts[0]), cv2.FONT_HERSHEY_SIMPLEX, 0.6, COLORS[c], 2)
        im = cv2.addWeighted(overlay, 0.35, im, 0.65, 0)
        cv2.imwrite(str(args.out / img_path.name), im)
    print(f"Đã vẽ {min(args.n, len(imgs))} ảnh vào {args.out}/")


if __name__ == "__main__":
    main()
```

### `check_tflite.py`

```python
"""In shape input/output của file .tflite để gửi lại cho người làm app.

  pip install ai-edge-litert   # hoặc dùng tensorflow nếu đã có
  python check_tflite.py best_float32.tflite
"""
import sys

try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:
    from tensorflow.lite.python.interpreter import Interpreter

it = Interpreter(model_path=sys.argv[1])
it.allocate_tensors()
for kind, details in (("INPUT", it.get_input_details()), ("OUTPUT", it.get_output_details())):
    for d in details:
        print(f"{kind:6} {d['name']}: shape={d['shape'].tolist()} dtype={d['dtype'].__name__}")
```
