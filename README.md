# Fieldline — Field Inventory & Edge AI

Ứng dụng **kiểm kê tài sản hiện trường** viết bằng Flutter. App cho phép quét mã QR/Barcode, nhận diện thiết bị và hư hỏng **ngay trên máy** bằng mô hình YOLO (TFLite), lập phiếu kiểm kê **ngoại tuyến** (Isar), ký xác nhận, chụp ảnh minh chứng, tự đồng bộ lên **Supabase** khi có mạng và xuất **báo cáo PDF A4**. Bản **web** đóng vai trò trung tâm quản lý dữ liệu.

> Đồ án cuối kỳ môn **Phát triển ứng dụng đa nền tảng**.

---

## Tính năng chính

### App hiện trường (iOS / Android / macOS)
- **Đăng nhập / đăng ký** bằng Supabase Auth. Phiên đăng nhập được giữ trên máy, nên sau lần đầu vẫn vào app được khi ngoại tuyến.
- **Quét mã** QR / EAN / UPC / Code128/39/93 / DataMatrix / PDF417. Hỗ trợ đèn flash, đổi camera, **nhập mã thủ công** khi camera lỗi.
- **Edge AI**: YOLO chạy on-device, nhận diện **9 lớp**:
  - Thiết bị: Tủ điện, Aptomat, Ghế, Bàn, Máy chiếu
  - Hư hỏng: Vết nứt, Gỉ sét, Thấm nước, Khuyết tật kim loại

  Trên iOS, mô hình chạy bằng **GPU (Metal)**, mỗi lượt nhận diện mất khoảng 0,3 giây. AI chỉ đọc phần ảnh **trong khung xanh**, và vẫn nhận diện được khi khung hình không có QR. Màn quét có thẻ **chẩn đoán AI** hiện thời gian xử lý và phần cứng đang dùng (GPU/CPU).
- **Phiếu kiểm kê**: tên tài sản, loại, khu vực, vị trí, tình trạng, số lượng, ghi chú, **ảnh minh chứng** (`image_picker`). Phiếu chưa ký được lưu thành **bản nháp**: bản nháp không đồng bộ, không vào báo cáo, có thể mở lại để ký hoặc xoá.
- **Ký xác nhận** trên canvas (lưu tên và chức vụ người ký), xuất ảnh PNG.
- **Offline-first**: mọi phiếu lưu vào Isar trước.
- **Tự động đồng bộ** phiếu đã ký khi có mạng (debounce 3 giây, retry lùi dần từ 30 giây đến tối đa 5 phút). Có thể đồng bộ tay ở màn Đồng bộ.
- **Danh mục tài sản**: thêm/sửa tài sản, lọc theo khu vực, xuất danh sách PDF. Khi máy và cloud sửa cùng một tài sản, app hiện **màn đối chiếu** để chọn giữ bản nào.
- **Tổng quan & Báo cáo**: số liệu thật, chọn kỳ báo cáo theo tháng, xem trước PDF nhiều trang trước khi chia sẻ.
- **Địa điểm & Cài đặt**: thống kê theo khu vực, cấu hình đồng bộ.

### Bản web (trung tâm quản lý — Card 28)
- Đọc/ghi trực tiếp trên Supabase, không dùng Isar.
- Không có chức năng quét, lập phiếu, ký hay đồng bộ ngoại tuyến. Các route `/scanner`, `/audit-form`, `/signature`, `/sync` tự chuyển về trang chủ.

## Tech stack

| Mảng | Công nghệ |
|---|---|
| Framework | Flutter (Dart `^3.13.4`) |
| State | `flutter_riverpod` + `riverpod_generator` |
| Routing | `go_router` (auth redirect, `ShellRoute`) |
| Camera / Scanner | `mobile_scanner` 7.4.2 (**bản vá cục bộ** trong `third_party/`), `permission_handler` |
| Edge AI | `tflite_flutter` (GPU delegate Metal trên iOS) — YOLOv8s, input 640×640 |
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
│   ├── ai_pipeline/ai_config.dart    # Đường dẫn model, inputSize, ngưỡng tin cậy
│   ├── database/local_db_init.dart   # initIsar() + isarInstanceProvider
│   ├── network/                      # supabase_config (không commit), provider, connectivity
│   ├── platform/app_mode.dart        # AppMode.field (mobile) / AppMode.console (web)
│   ├── router/app_router.dart        # GoRouter + auth guard
│   ├── theme/fieldline_theme.dart    # Theme "Fieldline" (theo Figma)
│   ├── utils/                        # pdf_report_generator, responsive_layout
│   └── widgets/                      # FieldlineShell (navigation), widget dùng chung
└── features/
    ├── auth/              # Supabase Auth, màn đăng nhập/đăng ký, tài khoản
    ├── edge_vision/       # Scanner + suy luận TFLite + panel chẩn đoán AI
    ├── offline_audit/     # Phiếu kiểm kê, Isar, ảnh minh chứng, sync & auto-sync
    ├── canvas_signature/  # Ký xác nhận
    ├── asset_catalog/     # Danh mục tài sản, editor, đối chiếu xung đột
    ├── report_dashboard/  # Tổng quan, báo cáo, xem trước PDF
    ├── workspace/         # Địa điểm, Cài đặt
    └── cloud_console/     # Dữ liệu và overrides cho bản web

supabase/
├── migrations/            # Thay đổi schema theo thời gian
└── seed/assets_sample.sql # 5 tài sản mẫu

third_party/mobile_scanner/ # Bản vá mobile_scanner (xem PATCH_NOTES.md)
assets/models/              # object_detection.tflite (~45 MB) + labels.txt
docs/kiem-thu/              # Biên bản kiểm thử thủ công
```

### Màn hình

| Route | Màn hình | Web |
|---|---|:-:|
| `/login`, `/register` | Đăng nhập / Đăng ký | ✅ |
| `/` | Tổng quan | ✅ |
| `/assets`, `/assets/new`, `/assets/:code` | Danh mục, thêm/sửa tài sản | ✅ |
| `/reports`, `/reports/preview` | Báo cáo, xem trước PDF | ✅ |
| `/locations`, `/settings` | Địa điểm, Cài đặt | ✅ |
| `/scanner` | Quét mã + Edge AI | ❌ |
| `/audit-form` | Lập phiếu kiểm kê | ❌ |
| `/signature` | Ký xác nhận | ❌ |
| `/sync`, `/sync/conflicts` | Đồng bộ, đối chiếu xung đột | ❌ |

### Pipeline Edge AI

- **Mô hình:** YOLOv8s (`best-new.pt`, huấn luyện ở 640) xuất sang TFLite float32 bằng LiteRT.
  - Input: `1×3×640×640` (NCHW).
  - Output: `1×(4+9)×8400` gồm `cx, cy, w, h` rồi đến điểm của từng lớp.
  - So với model trước (`best.pt`, huấn luyện ở 800): mAP50-95 tập val từ 0.576 lên **0.761**, mAP50 từ 0.793 lên **0.855**, recall từ 0.760 lên **0.807**. Hai lần huấn luyện dùng tập dữ liệu khác nhau nên các số này chỉ để tham khảo.
- **Phần cứng chạy:** iOS dùng **GPU delegate Metal** (cho phép FP16). Nếu Metal lỗi, app tự chuyển sang CPU 4 luồng. Đo trên iPhone 11 Pro Max: phần mô hình mất 98–153 ms (CPU cũ mất vài giây).
- **Tiền xử lý:** AI chỉ nhận ô vuông giữa khung hình, cạnh bằng 70% cạnh ngắn (`AiConfig.cropFraction`), khớp với khung xanh trên màn quét.
  - iOS: bản vá `mobile_scanner` cắt và thu nhỏ ô này về RGB 640×640 bằng CoreGraphics, gửi sang Dart qua khóa `aiInput`. Dart chỉ còn đổi mảng này sang tensor.
  - Nền tảng khác: giải mã JPEG bằng `dart:ui` (thu nhỏ ngay lúc giải mã), rồi cắt ô giữa.
- **Ngưỡng tin cậy:** `0.5` cho thiết bị, `0.7` cho nhóm hư hỏng (lớp 0, 1, 2, 5). Nhóm hư hỏng dùng ngưỡng cao hơn vì ma trận nhầm lẫn cho thấy các lớp này báo nhầm nhiều ở vùng nền.
- **Bảo vệ CPU:** nếu AI đang xử lý thì bỏ qua (drop) frame mới.
- **Bản vá `mobile_scanner` (iOS/macOS):**
  1. Plugin gốc bỏ qua frame không có mã. Bản vá vẫn gửi frame (khoảng 2 frame/giây) để AI chạy được khi không có QR.
  2. Gửi kèm `aiInput` (ảnh 640×640 đã cắt theo khung quét) như mô tả ở trên.

  Chi tiết xem `third_party/mobile_scanner/PATCH_NOTES.md`.
  > ⚠️ Android **chưa vá**, nên trên Android AI chỉ chạy khi camera thấy mã.
- **Hạn chế đã biết:** model hiện tại thiên về lớp **Aptomat**. Máy chiếu và tủ điện đóng cửa thường bị báo là Aptomat với độ tin cậy 90–95%, vết nứt đôi khi bị báo là Thấm nước. Cần bổ sung ảnh máy chiếu, tủ điện, vết nứt và cân bằng số ảnh giữa các lớp rồi huấn luyện lại.

### Dữ liệu

**Isar — `AuditRecordModel`**

| Nhóm | Trường |
|---|---|
| Tài sản | `scanCode`, `assetName`, `aiDetectedLabel`, `quantity` |
| Vị trí & tình trạng | `area`, `location`, `condition`, `notes` |
| Ký xác nhận | `signatureBytes`, `signerName`, `signerRole` |
| Minh chứng | `photoFiles` |
| Đồng bộ | `signatureUrl`, `timestamp`, `isSynced` |

**Isar — `AssetModel`:** `name`, `category`, `area`, `location`, `quantity`, `status`, `lastAuditAt`, `updatedAt`, `isSynced`, cùng `baseJson` / `conflictJson` để đối chiếu 3 bên.

**Supabase**
- Bảng: `audit_records`, `assets`, `profiles`.
- Storage bucket: `signatures` (ảnh chữ ký), `evidence` (ảnh minh chứng).
- **RLS:** chỉ người đã đăng nhập mới truy cập được dữ liệu. Phiếu kiểm kê chỉ người tạo (`created_by`) được sửa.

## Cài đặt & chạy

### Yêu cầu
- Flutter SDK hỗ trợ Dart `>= 3.13.4`
- Xcode + CocoaPods (iOS/macOS); Android Studio + Android SDK (Android)
- Một project Supabase
- Máy thật để thử camera và AI (simulator không có camera)

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

Nếu cần dữ liệu mẫu, chạy thêm `supabase/seed/assets_sample.sql`.

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
  - Theo biên bản kiểm thử Sprint 6 có 2 lỗi build còn mở:
    1. `tflite_flutter` lệch JVM target (11 so với 17).
    2. `permission_handler_android` yêu cầu `compileSdk >= 37`.

    Chi tiết xem `docs/kiem-thu/sprint6-card19.md`.
- **Web:** không có camera, AI hay lưu ngoại tuyến (xem phần Bản web ở trên).

## Kiểm thử

```bash
flutter test
```

| Thư mục test | Phạm vi |
|---|---|
| `test/core/utils/` | PDF báo cáo, PDF danh sách tài sản, responsive layout |
| `test/features/auth/` | Luồng đăng nhập/đăng ký |
| `test/features/edge_vision/` | Use case xử lý mã quét, repository AI, màn quét, chẩn đoán AI |
| `test/features/offline_audit/` | Form, bản nháp, ảnh minh chứng, model cloud, sync, auto-sync |
| `test/features/asset_catalog/` | Model, merge/đối chiếu, các màn tài sản |
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

## Quy trình Git

- Nhánh: `main` ← `develop` ← `feature/sprint<S>-card<N>-tv<K>`. Mọi thay đổi vào `develop` đều qua Pull Request.
- Commit theo [Conventional Commits](https://www.conventionalcommits.org/), ví dụ:

  ```
  feat(card26): đăng nhập, đăng ký bằng Supabase Auth và khoá dữ liệu theo tài khoản
  fix(ai): mô hình Edge AI bị huỷ ngay sau khi nạp nên không nhận diện được
  ```
