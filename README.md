# Fieldline — Đánh giá cơ sở vật chất trường học bằng Edge AI

Ứng dụng Flutter giúp **đánh giá hư hỏng cơ sở vật chất trong trường học** và **ước tính chi phí sửa chữa**:

- Kiểm tra viên quét **thẻ QR 10×10 cm** dán trên bề mặt (tường, trần, sàn, cửa sắt, lan can…).
- AI chạy **ngay trên máy** (YOLO, TFLite) tìm vùng hư hỏng. Thẻ QR đóng vai thước đo để quy ra **m²** hoặc **mét dài**.
- App tính **chỉ số hư hại**, **mức độ** và **chi phí sửa chữa** theo bảng đơn giá do nhà trường quản lý.
- Phiếu được ký xác nhận, lưu **ngoại tuyến** (Isar), tự đồng bộ lên **Supabase** khi có mạng.
- Kết quả tổng hợp thành **báo cáo PDF A4**: chi phí theo tòa nhà, danh sách phòng cần ưu tiên sửa.

Bản **web** là trung tâm quản lý: xem số liệu, báo cáo và quản lý bảng đơn giá.

> Đồ án cuối kỳ môn **Phát triển ứng dụng đa nền tảng**. Phạm vi ban đầu là kiểm kê tài sản hiện trường, sau đó được thu hẹp về đánh giá cơ sở vật chất trường học để giảm chi phí huấn luyện AI.

---

## Luồng sử dụng

```
Quét thẻ QR trên bề mặt
 → AI tìm vùng hư hỏng trong khung xanh, thẻ QR làm thước đo
 → Phiếu: chọn chất liệu, nhập/kiểm tra diện tích bề mặt, sửa số đo nếu cần
 → App tính chỉ số, mức độ, chi phí theo bảng đơn giá
 → Ký xác nhận → lưu trên máy → tự đồng bộ
 → Tổng quan / Báo cáo / PDF: chi phí theo tòa nhà, phòng, mức ưu tiên
```

## Tính năng chính

### App hiện trường (iOS / Android / macOS)
- **Đăng nhập / đăng ký** bằng Supabase Auth. Phiên đăng nhập được giữ trên máy, nên sau lần đầu vẫn vào được app khi ngoại tuyến.
- **Quét mã** QR / EAN / UPC / Code128/39/93 / DataMatrix / PDF417, có đèn flash, đổi camera, **nhập mã thủ công**.
- **Đo hư hỏng bằng thẻ QR:**
  - Ngay khi đọc được mã, app chạy AI trên chính khung đó.
  - Kích thước thật được quy đổi từ cạnh thẻ QR trên ảnh (`AiConfig.markerSizeCm`, mặc định 10 cm).
  - Khi thẻ quá nhỏ hoặc mờ, app vẫn liệt kê loại hư hỏng để người kiểm tra tự nhập số đo.
- **Đánh giá bề mặt trên phiếu:**
  - Chọn chất liệu, nhập diện tích bề mặt (tự điền nếu danh mục đã có), sửa, thêm hoặc xoá vùng hư hỏng.
  - Xem ngay mức độ, chỉ số, cách xử lý và chi phí từng hạng mục.
  - Tình trạng phiếu tự chuyển theo mức hư hỏng nặng nhất.
- **Ảnh minh chứng**, **ký xác nhận** trên canvas (tên, chức vụ người ký).
- **Bản nháp:** phiếu chưa ký không đồng bộ và không vào báo cáo.
- **Offline-first và tự đồng bộ:** debounce 3 giây, retry lùi dần từ 30 giây đến tối đa 5 phút. Bảng đơn giá được lưu trên máy nên **tính được tiền cả khi ngoại tuyến**.
- **Phòng & bề mặt:** danh mục theo tòa nhà / phòng, có chất liệu và diện tích bề mặt. Khi máy và cloud sửa cùng một mục, app hiện màn đối chiếu.
- **Tổng quan & Báo cáo:**
  - Chi phí sửa chữa ước tính, **điểm cơ sở vật chất** (0–100), số bề mặt theo mức Nặng / Vừa / Nhẹ, các phòng cần ưu tiên.
  - Chọn kỳ báo cáo theo tháng, xem trước PDF.

### Bản web (trung tâm quản lý)
- Đọc/ghi trực tiếp trên Supabase, không dùng Isar.
- **Bảng đơn giá sửa chữa** (`/repair-rates`): ai cũng xem được, **chỉ quản trị viên** được thêm, sửa, xoá.
- Không có chức năng quét, lập phiếu, ký hay đồng bộ ngoại tuyến. Các route `/scanner`, `/audit-form`, `/signature`, `/sync` tự chuyển về trang chủ.

## Cách tính chỉ số và chi phí

| Bước | Quy tắc |
|---|---|
| Khối lượng | Thấm/mốc, bong sơn, gỉ sét đo theo **m²**; vết nứt đo theo **mét dài**. Với model hiện tại (khung chữ nhật): diện tích ≈ diện tích khung × π/4, chiều dài nứt ≈ đường chéo khung |
| Chỉ số hư hại (0–100) | Loại theo m²: diện tích hư ÷ diện tích bề mặt × 100. Vết nứt: (mét nứt ÷ m² bề mặt) ÷ 2 m/m² × 100. Các vùng cùng loại được cộng trước khi tính |
| Mức độ | Dưới 5: **Nhẹ**; 5–20: **Vừa**; từ 20: **Nặng** |
| Xử lý toàn bộ | Loại theo m² có chỉ số từ 40: tính tiền theo **cả diện tích bề mặt** |
| Chi phí | Khối lượng × đơn giá theo (chất liệu, loại hư hỏng, mức độ). Ưu tiên đơn giá riêng của chất liệu, không có thì dùng giá chung |
| Điểm bề mặt | 100 − tổng chỉ số các loại (tối thiểu 0). Điểm cơ sở vật chất là trung bình các bề mặt |

- Các ngưỡng nằm trong `AssessmentConfig` (`lib/features/damage_assessment/domain/damage_calculator.dart`) và **cần hiệu chỉnh** với số đo thực tế.
- Phiếu lưu cả đơn giá tại thời điểm kiểm tra, nên báo cáo cũ không đổi khi bảng giá thay đổi.
- Một bề mặt kiểm tra nhiều lần thì báo cáo chỉ lấy phiếu mới nhất.

> ⚠️ Bảng giá trong `supabase/seed/repair_cost_rates_sample.sql` là **giá minh hoạ** (cờ `is_sample`), chưa phải giá thật của nhà trường. Quản trị viên cần sửa lại ở màn Bảng đơn giá. Chi phí trong app và báo cáo luôn là **ước tính**.

## Tech stack

| Mảng | Công nghệ |
|---|---|
| Framework | Flutter (Dart `^3.13.4`) |
| State | `flutter_riverpod` + `riverpod_generator` |
| Routing | `go_router` (auth redirect, `ShellRoute`) |
| Camera / Scanner | `mobile_scanner` 7.4.2 (**bản vá cục bộ** trong `third_party/`), `permission_handler` |
| Edge AI | `tflite_flutter` (GPU delegate Metal trên iOS), input 640×640 |
| Local DB | `isar_plus` |
| Backend | `supabase_flutter` (Postgres + RLS, Auth, Storage) |
| Mạng | `connectivity_plus`, `http` |
| PDF | `pdf`, `printing` |
| Khác | `signature`, `image_picker`, `shared_preferences`, `flex_color_scheme`, `google_fonts`, `fpdart`, `freezed` |

## Kiến trúc

Dự án theo **Clean Architecture, chia theo feature**: `domain` (entity, abstract repository, use case) → `data` (model, repository impl) → `presentation` (controller, screen, widget).

```
lib/
├── main.dart                     # Khởi tạo Supabase; mobile: Isar, web: console overrides
├── core/
│   ├── ai_pipeline/ai_config.dart    # Model, inputSize, ngưỡng, ánh xạ lớp → loại hư hỏng, cỡ thẻ QR
│   ├── database/local_db_init.dart   # initIsar() + isarInstanceProvider
│   ├── network/                      # supabase_config (không commit), provider, connectivity
│   ├── platform/app_mode.dart        # AppMode.field (mobile) / AppMode.console (web)
│   ├── router/app_router.dart        # GoRouter + auth guard
│   ├── theme/fieldline_theme.dart    # Theme "Fieldline" (theo Figma)
│   ├── utils/                        # pdf_report_generator, responsive_layout
│   └── widgets/                      # FieldlineShell (navigation), widget dùng chung
└── features/
    ├── auth/              # Supabase Auth, màn đăng nhập/đăng ký, tài khoản
    ├── edge_vision/       # Scanner, suy luận TFLite, giải mã khung YOLO (NMS), bước đo
    ├── damage_assessment/ # Đo theo thẻ QR, tính chỉ số/chi phí, bảng đơn giá, thẻ chi phí
    ├── offline_audit/     # Phiếu kiểm tra, Isar, ảnh minh chứng, sync & auto-sync
    ├── canvas_signature/  # Ký xác nhận
    ├── asset_catalog/     # Danh mục phòng & bề mặt, editor, đối chiếu xung đột
    ├── report_dashboard/  # Tổng quan, báo cáo, xem trước PDF
    ├── workspace/         # Địa điểm, Cài đặt
    └── cloud_console/     # Dữ liệu và overrides cho bản web

supabase/
├── migrations/            # Thay đổi schema theo thời gian
└── seed/                  # 9 bề mặt mẫu của 2 tòa nhà, bảng đơn giá minh hoạ

third_party/mobile_scanner/ # Bản vá mobile_scanner (xem PATCH_NOTES.md)
assets/models/              # object_detection.tflite + labels.txt
docs/ai-training/           # Hướng dẫn train model phân vùng 4 lớp bề mặt
docs/kiem-thu/              # Biên bản kiểm thử thủ công
```

### Màn hình

| Route | Màn hình | App hiện trường | Bản web |
|---|---|:-:|:-:|
| `/login`, `/register` | Đăng nhập / Đăng ký | ✅ | ✅ |
| `/` | Tổng quan (có chi phí sửa chữa) | ✅ | ✅ |
| `/assets`, `/assets/new`, `/assets/:code` | Phòng & bề mặt, thêm/sửa | ✅ | ✅ |
| `/reports`, `/reports/preview` | Báo cáo, xem trước PDF | ✅ | ✅ |
| `/repair-rates` | Bảng đơn giá sửa chữa (admin sửa) | ✅ | ✅ |
| `/locations`, `/settings` | Địa điểm, Cài đặt | ✅ | ✅ |
| `/scanner` | Quét thẻ QR + đo hư hỏng | ✅ | — ¹ |
| `/audit-form` | Lập phiếu, đánh giá bề mặt | ✅ | — ² |
| `/signature` | Ký xác nhận | ✅ | — ² |
| `/sync`, `/sync/conflicts` | Đồng bộ, đối chiếu xung đột | ✅ | — ³ |

**—** = không dùng trên web theo thiết kế, không phải tính năng còn thiếu.
1. Trình duyệt không chạy được TFLite (cần `dart:ffi`), và việc quét cần camera của thiết bị hiện trường.
2. Phiếu phải lưu ngoại tuyến vào Isar trước rồi mới ký, mà bản web không dùng Isar.
3. Bản web đọc và ghi thẳng lên Supabase, không có dữ liệu ngoại tuyến cần đồng bộ.

### Pipeline Edge AI

- **Model hiện tại:** YOLOv8s phát hiện 9 lớp (từ phạm vi cũ), input `1×3×640×640`, output `1×(4+9)×8400`. App chỉ dùng 3 lớp hư hỏng:
  - Vết nứt
  - Gỉ sét (gộp cả "Khuyết tật kim loại")
  - Thấm nước

  Các lớp đồ vật bị bỏ qua. Ánh xạ nằm ở `AiConfig.damageTypeByClass`.
- **Model thay thế (đang train):** YOLOv8n-seg **phân vùng 4 lớp bề mặt**: vết nứt, thấm/ẩm mốc, bong tróc sơn, gỉ sét. Model này đo theo mask thay vì khung chữ nhật. Hướng dẫn và script nằm ở [`docs/ai-training/HUONG_DAN_TRAIN_MODEL_BE_MAT.md`](docs/ai-training/HUONG_DAN_TRAIN_MODEL_BE_MAT.md).
- **Giải mã:** mỗi ô lấy lớp có điểm cao nhất, lọc theo ngưỡng (`0.5` thường, `0.7` cho lớp hư hỏng), rồi NMS theo từng lớp (IoU 0,45).
- **Phần cứng chạy:** iOS dùng **GPU delegate Metal** (cho phép FP16), lỗi thì tự chuyển sang CPU 4 luồng. Đo trên iPhone 11 Pro Max: phần mô hình mất 98–153 ms.
- **Tiền xử lý:** AI chỉ nhận ô vuông giữa khung hình, cạnh bằng 70% cạnh ngắn (`AiConfig.cropFraction`), khớp khung xanh trên màn quét.
  - **iOS:** bản vá `mobile_scanner` cắt ô này về RGB 640×640 bằng CoreGraphics và gửi qua khóa `aiInput`. Toạ độ góc mã QR và ô cắt cùng nằm trên một ảnh gốc, nên phép quy đổi kích thước không phụ thuộc chiều xoay máy.
  - **Nền tảng khác:** giải mã JPEG bằng `dart:ui` rồi cắt ô giữa.
- **Bản vá `mobile_scanner` (iOS/macOS):** vẫn gửi frame khi không có mã (khoảng 2 frame/giây) và gửi kèm `aiInput`. Chi tiết xem `third_party/mobile_scanner/PATCH_NOTES.md`.
  > ⚠️ Android **chưa vá**, nên trên Android AI chỉ chạy khi camera thấy mã. Luồng đo vẫn hoạt động vì luôn quét thẻ QR, nhưng toạ độ góc mã trên Android chưa được kiểm tra.
- **Hạn chế đã biết:**
  - Số đo theo khung chữ nhật chỉ là ước lượng.
  - Kết quả chỉ đúng khi thẻ QR và vùng hư hỏng nằm trên cùng mặt phẳng và chụp gần thẳng góc.
  - Model cũ chưa có lớp bong tróc sơn.

### Dữ liệu

**Isar: `AuditRecordModel`**

| Nhóm | Trường |
|---|---|
| Bề mặt | `scanCode`, `assetName`, `aiDetectedLabel`, `quantity` (chỉ dùng cho phiếu kiểm kê thường) |
| Tòa nhà / phòng & tình trạng | `area` (tòa nhà / tầng), `location` (phòng), `condition`, `notes` |
| Đánh giá hư hỏng | `damageAssessmentJson` (chất liệu, diện tích, số đo, kết quả từng loại kèm đơn giá lúc kiểm tra), `estimatedCost`, `damageIndex` |
| Ký xác nhận | `signatureBytes`, `signerName`, `signerRole` |
| Minh chứng | `photoFiles` |
| Đồng bộ | `signatureUrl`, `timestamp`, `isSynced` |

**Isar: `AssetModel`** gồm:
- `name`, `category` (chất liệu / loại), `area`, `location`, `quantity`, `surfaceAreaM2`, `status`
- `lastAuditAt`, `updatedAt`, `isSynced`
- `baseJson` / `conflictJson` để đối chiếu 3 bên

**Supabase**
- **Bảng:** `audit_records`, `assets`, `profiles`, `repair_cost_rates`.
- **Storage bucket:** `signatures` (ảnh chữ ký), `evidence` (ảnh minh chứng).
- **RLS:**
  - Chỉ người đã đăng nhập mới truy cập được dữ liệu.
  - Phiếu chỉ người tạo (`created_by`) được sửa.
  - Bảng đơn giá chỉ admin (`profiles.role = 'admin'`) được thêm, sửa, xoá.

## Cài đặt & chạy

### Yêu cầu
- Flutter SDK hỗ trợ Dart `>= 3.13.4`
- Xcode + CocoaPods (iOS/macOS); Android Studio + Android SDK (Android)
- Một project Supabase
- Máy thật để thử camera và AI (simulator không có camera)
- Thẻ QR in đúng **10×10 cm**, nội dung là mã bề mặt trong danh mục

### 1. Lấy mã nguồn & cài package

```bash
git clone https://github.com/longtapdanhcode/Finalterm_DANENTANG.git
cd Finalterm_DANENTANG
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Cấu hình Supabase

```bash
cp lib/core/network/supabase_config.dart.example lib/core/network/supabase_config.dart
```

Điền `url` và `anonKey` (publishable key) lấy từ **Supabase Dashboard → Project Settings → API**. File `supabase_config.dart` đã nằm trong `.gitignore`, **không commit file này**.

Nếu để trống, app vẫn khởi động. Tuy nhiên đăng nhập là bắt buộc, nên để dùng app thật cần cấu hình đầy đủ.

### 3. Khởi tạo database

Bước này giả định bảng `public.audit_records` và bucket `signatures` (tạo ở Card 10) đã có sẵn. Sau đó chạy lần lượt các file trong `supabase/migrations/` theo thứ tự tên file, bằng Supabase CLI (`supabase db push`) hoặc dán vào SQL Editor:

| Migration | Nội dung |
|---|---|
| `20261024120000_add_audit_record_details` | Thêm `area`, `location`, `condition`, `notes` |
| `20261024150000_add_asset_name_and_signer` | Thêm `asset_name`, `signer_name`, `signer_role` |
| `20261026090000_create_assets` | Tạo bảng `assets` |
| `20261028090000_add_audit_evidence_photos` | Thêm `photo_urls` và bucket `evidence` |
| `20261030090000_auth_profiles_and_rls` | Tạo bảng `profiles`, thêm `created_by`, siết RLS theo tài khoản |
| `20261112090000_damage_assessment_and_repair_rates` | Tạo bảng đơn giá `repair_cost_rates` (chỉ admin sửa); thêm `damage_assessment`, `estimated_cost`, `damage_index` cho phiếu và `surface_area_m2` cho tài sản |
| `20261112093000_revoke_anon_is_admin` | Không cho `anon` gọi hàm `is_admin()` qua API |

Dữ liệu mẫu (tuỳ chọn):
- `supabase/seed/assets_sample.sql`: 9 bề mặt trong 2 tòa nhà, có chất liệu và diện tích.
- `supabase/seed/repair_cost_rates_sample.sql`: bảng đơn giá **minh hoạ**.

Tạo tài khoản quản trị: xem hướng dẫn ở cuối migration `20261030090000_auth_profiles_and_rls.sql`.

### 4. Chạy

```bash
flutter run                 # mobile / macOS (chế độ hiện trường)
flutter run -d chrome       # bản web (trung tâm quản lý)
```

## Lưu ý theo nền tảng

- **iOS:**
  - Impeller đã được tắt trong `Info.plist` (`FLTEnableImpeller = false`) để tránh màn hình camera bị đen. Khi chạy CLI có thể thêm `--no-enable-impeller`.
  - Quyền camera đã khai báo qua `NSCameraUsageDescription`.
- **Android:**
  - Đã khai báo quyền `CAMERA`.
  - Build APK release dùng `compileSdk 37` và đã chỉnh JVM target cho `tflite_flutter`.
  - `mobile_scanner` chưa vá trên Android (xem phần Pipeline Edge AI).
- **Web:** không có camera, AI hay lưu ngoại tuyến (xem phần Bản web ở trên).

## Kiểm thử

```bash
flutter test
```

| Thư mục test | Phạm vi |
|---|---|
| `test/core/utils/` | PDF báo cáo, PDF danh sách, responsive layout |
| `test/features/auth/` | Luồng đăng nhập/đăng ký |
| `test/features/edge_vision/` | Giải mã khung YOLO + NMS, bước đo khi quét, repository AI, màn quét, chẩn đoán AI |
| `test/features/damage_assessment/` | Đo theo thẻ QR, tính chỉ số/chi phí, bảng đơn giá (offline, khớp seed), phiếu có đánh giá, thống kê chi phí, PDF, màn đơn giá |
| `test/features/offline_audit/` | Form, bản nháp, ảnh minh chứng, model cloud, sync, auto-sync |
| `test/features/asset_catalog/` | Model, merge/đối chiếu, các màn danh mục |
| `test/features/report_dashboard/` | Thống kê, chọn kỳ báo cáo, dashboard |
| `test/features/workspace/`, `cloud_console/` | Địa điểm, Cài đặt, bản web |
| `test/helpers/` | Fake cho auth và ảnh minh chứng |

Biên bản kiểm thử thủ công nằm trong `docs/kiem-thu/`.

## Lộ trình phát triển

| Sprint | Card | Nội dung |
|---|---|---|
| 1 | 1–3 | Dataset, cấu hình AI, xuất model TFLite |
| 2 | 4–6 | Khung Flutter + Clean Architecture, scanner, inference on-device |
| 3 | 7–9 | Isar offline-first, form kiểm kê, canvas chữ ký |
| 4 | 10–12 | Supabase Cloud Sync, PDF A4, UI responsive |
| 5 | 13 | Dọn dẹp mã nguồn, kiểm thử |
| 6 | 17–19 | Giao diện Fieldline (Figma), trạng thái mạng thật, tên tài sản & người ký, kiểm thử iOS |
| 7 | 20–22 | Danh mục tài sản thật, thêm/sửa & xuất PDF, số liệu thật cho Tổng quan/Báo cáo |
| 8 | 23–25 | Ảnh minh chứng, tự động đồng bộ, đối chiếu xung đột tài sản |
| 9 | 26–28 | Supabase Auth + RLS, màn Địa điểm & Cài đặt, bản web quản lý |
| 10 | — | Model YOLOv8s mới, Edge AI chạy GPU Metal, cắt ảnh theo khung quét ở phía native |
| 11 | — | Thu hẹp phạm vi về cơ sở vật chất trường học: đo hư hỏng theo thẻ QR, chỉ số và chi phí sửa chữa, bảng đơn giá, báo cáo chi phí |
| 12 | — | (Đang làm) Model phân vùng 4 lớp bề mặt, đo theo mask |

## Quy trình Git

- Nhánh: `main` ← `develop` ← `feature/sprint<S>-card<N>-tv<K>`. Mọi thay đổi vào `develop` đều qua Pull Request.
- Commit theo [Conventional Commits](https://www.conventionalcommits.org/), ví dụ:

  ```
  feat(card26): đăng nhập, đăng ký bằng Supabase Auth và khoá dữ liệu theo tài khoản
  fix(ai): mô hình Edge AI bị huỷ ngay sau khi nạp nên không nhận diện được
  ```
