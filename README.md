# Field Inventory & Edge AI Suite
### Giải pháp kiểm kê tài sản & thiết bị hiện trường tích hợp AI chạy trên thiết bị

[![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?logo=flutter)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_3-2F74C0)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Local_DB-Isar_Plus-4A154B)](https://pub.dev/packages/isar_plus)
[![Edge AI](https://img.shields.io/badge/Edge_AI-YOLO_→_TFLite-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![Backend](https://img.shields.io/badge/BaaS-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![Tests](https://img.shields.io/badge/Tests-150%2F150_Passed-success)](test/)
[![Analysis](https://img.shields.io/badge/Analyze-0_Issues-brightgreen)](#chất-lượng-mã-nguồn)

---

## Giới thiệu

**Field Inventory & Edge AI Suite** hỗ trợ kiểm kê viên ghi nhận và quản lý tài sản, thiết bị ngay tại hiện trường. Hệ thống gồm hai phần:

- **App điện thoại (iOS)** – công cụ chính ở hiện trường: quét QR / mã vạch, nhận diện thiết bị và hư hỏng bằng AI chạy ngay trên máy, lập phiếu kèm ảnh minh chứng, ký xác nhận. Làm việc **ngoại tuyến**, tự đồng bộ khi có mạng.
- **Bản web** – trung tâm quản lý dữ liệu: xem toàn bộ phiếu do các điện thoại gửi lên, quản lý danh mục tài sản, báo cáo và xuất PDF. Không quét camera.

Dữ liệu dùng chung qua **Supabase** (PostgreSQL, Storage, Auth), khoá theo tài khoản đăng nhập.

---

## Tính năng

### Hiện trường (app điện thoại)
- **Quét mã** QR / mã vạch bằng `mobile_scanner` (bản vá trong `third_party/` để AI nhận khung hình cả khi không có mã), đèn flash, đổi camera, nhập mã thủ công.
- **Edge AI**: mô hình YOLO tự huấn luyện (9 lớp: Vết nứt, Gỉ sét, Thấm nước, Tủ điện, Aptomat, Khuyết tật kim loại, Ghế, Bàn, Máy chiếu) xuất sang TFLite, chạy trong isolate riêng; ngưỡng 50% cho thiết bị, 70% cho hư hỏng. Có **thẻ chẩn đoán AI** (trạng thái mô hình, số khung, thời gian xử lý, điểm cao nhất).
- **Phiếu kiểm kê**: số lượng, khu vực, vị trí, tình trạng, ghi chú, tối đa **3 ảnh minh chứng** (chụp hoặc chọn thư viện). Lưu **bản nháp** để ký sau, xoá nháp có xác nhận.
- **Ký xác nhận** trên canvas; họ tên và vai trò người ký tự điền theo tài khoản.
- **Ngoại tuyến** với Isar; **tự đồng bộ** khi mở app, có mạng lại, chuyển Wi-Fi, quay lại từ nền hoặc vừa ký phiếu; thử lại với khoảng chờ tăng dần; tuỳ chọn *Chỉ tải ảnh qua Wi-Fi*.
- **Đối chiếu dữ liệu khác phiên bản**: gộp ba chiều danh mục tài sản; mục hai bên cùng sửa thì người dùng chọn giữ bản trên máy hay bản đám mây.

### Quản lý (app & web)
- **Đăng nhập / Đăng ký** bằng Supabase Auth (bắt buộc; phiên lưu trên máy nên vẫn dùng ngoại tuyến). Vai trò Kiểm kê viên / Quản trị viên.
- **Tổng quan**: tiến độ kiểm kê theo khu vực, phiếu gần đây, tài sản cần xử lý.
- **Tài sản & thiết bị**: thêm/sửa, tìm kiếm, lọc theo khu vực và tình trạng, xuất danh sách PDF.
- **Báo cáo**: chọn kỳ theo tháng, xem trước PDF nhiều trang và xuất PDF có chữ ký, ảnh minh chứng (bản nháp không vào báo cáo).
- **Địa điểm**: khu vực, vị trí, tiến độ từng khu vực; chạm để mở danh mục đã lọc.
- **Cài đặt**: tài khoản, nơi kiểm kê và ca làm việc, đồng bộ, thông tin mô hình AI, dữ liệu trên máy.

---

## Kiến trúc

Feature-first Clean Architecture (mỗi module có `data / domain / presentation`), Riverpod 3 cho state và DI, go_router cho điều hướng.

```
lib/
├── core/
│   ├── ai_pipeline/        # Cấu hình mô hình: kích thước ảnh, ngưỡng tin cậy
│   ├── database/           # Khởi tạo Isar (app điện thoại)
│   ├── network/            # Supabase client, trạng thái mạng
│   ├── platform/           # Chế độ chạy: điện thoại (field) / web (console)
│   ├── router/             # go_router + chặn đăng nhập, chặn màn quét trên web
│   ├── theme/ widgets/     # Hệ thống giao diện Fieldline
│   └── utils/              # Tạo PDF, bố cục responsive
├── features/
│   ├── edge_vision/        # Quét mã, Edge AI TFLite, chẩn đoán AI
│   ├── offline_audit/      # Phiếu, bản nháp, ảnh minh chứng, đồng bộ & tự đồng bộ
│   ├── canvas_signature/   # Ký xác nhận
│   ├── asset_catalog/      # Danh mục tài sản, gộp ba chiều, đối chiếu xung đột
│   ├── report_dashboard/   # Tổng quan, báo cáo, xem trước PDF
│   ├── auth/               # Đăng nhập, đăng ký, hồ sơ, đăng xuất
│   ├── workspace/          # Địa điểm & Cài đặt
│   └── cloud_console/      # Nguồn dữ liệu Supabase cho bản web
└── main.dart               # Điện thoại: Isar + đồng bộ; Web: đọc/ghi thẳng Supabase
```

**Hai chế độ chạy** (`lib/core/platform/app_mode.dart`):

| | App điện thoại | Bản web |
|---|---|---|
| Nguồn dữ liệu | Isar trên máy, đồng bộ Supabase | Supabase trực tiếp (tải lại mỗi phút) |
| Quét mã, AI, lập phiếu, ký | Có | Không (ẩn và chặn đường dẫn) |
| Tổng quan, Tài sản, Báo cáo, Địa điểm, Cài đặt | Có | Có |
| AI TFLite | Chạy trên máy | Thay bằng bản rỗng (web không có `dart:ffi`) |

---

## Công nghệ chính

| Thư viện | Vai trò |
| :--- | :--- |
| `flutter_riverpod` 3, `riverpod_annotation` | State, DI, sinh provider |
| `go_router` | Điều hướng, chặn đăng nhập |
| `isar_plus` | CSDL ngoại tuyến (phiếu, tài sản) |
| `mobile_scanner` (bản vá cục bộ) | Camera, quét QR / mã vạch, cấp khung hình cho AI |
| `tflite_flutter`, `image` | Chạy mô hình YOLO on-device, tiền xử lý letterbox 640×640 |
| `signature` | Canvas chữ ký |
| `image_picker` | Ảnh minh chứng |
| `pdf`, `printing` | Tạo, xem trước và chia sẻ PDF (font Inter tiếng Việt) |
| `supabase_flutter` | Auth, PostgreSQL, Storage |
| `connectivity_plus` | Trạng thái mạng, Wi-Fi cho tự đồng bộ |
| `shared_preferences`, `http` | Thiết lập và tải ảnh trên bản web |

---

## Supabase

Chạy lần lượt các file trong `supabase/migrations/` bằng **Dashboard → SQL Editor**:

| Migration | Nội dung |
| :--- | :--- |
| `20261024120000_add_audit_record_details.sql` | Chi tiết phiếu (khu vực, vị trí, tình trạng, ghi chú) |
| `20261024150000_add_asset_name_and_signer.sql` | Tên tài sản, người ký |
| `20261026090000_create_assets.sql` | Bảng danh mục `assets` |
| `20261028090000_add_audit_evidence_photos.sql` | Cột `photo_urls`, bucket `evidence` |
| `20261030090000_auth_profiles_and_rls.sql` | Bảng `profiles`, cột `created_by`, khoá dữ liệu cho tài khoản đã đăng nhập |

Tạo tài khoản admin: **Authentication → Users → Add user** (tích *Auto Confirm User*), rồi chạy câu `update public.profiles set role = 'admin' ...` ở cuối migration cuối cùng.

---

## Cài đặt & chạy

**Yêu cầu:** Flutter 3.47 (Dart ≥ 3.13), Xcode cho iOS, tài khoản Supabase.

```bash
git clone https://github.com/longtapdanhcode/DoAnCN2-test.git
cd DoAnCN2-test
flutter pub get

# Cấu hình Supabase (file này không được commit)
cp lib/core/network/supabase_config.dart.example lib/core/network/supabase_config.dart
# rồi điền URL và anon key trong Project Settings → API

flutter test          # 150 test
flutter analyze       # 0 lỗi
```

**App điện thoại (iOS, nên dùng bản release trên máy thật):**

```bash
flutter run --release -d <id-thiết-bị>
```

**Bản web:**

```bash
flutter build web
python3 -m http.server 8080 --directory build/web
```

Mở `http://localhost:8080` và đăng nhập.

---

## Chất lượng mã nguồn

```
• flutter analyze        : 0 issues
• flutter test           : 150 / 150 passed (28 file test, ~4.500 dòng)
• Mã viết tay (lib/)     : 72 file, ~14.700 dòng
• Mã sinh tự động        : ~6.800 dòng (.g.dart)
• Thiết bị đã chạy thật  : iPhone 11 Pro Max (iOS 17.7), Chrome (bản web)
```

---

## Tiến độ theo Sprint (Trello)

- **Sprint 1 – Computer Vision & AI Pipeline:** Card 1 dataset ✅ · Card 2 huấn luyện ⚠️ (chưa nhận ra vết nứt) · Card 3 xuất TFLite ⚠️ (bản float32 42 MB, chưa lượng tử hoá)
- **Sprint 2 – Flutter Core & Edge AI:** Card 4–6 ✅
- **Sprint 3 – Offline-First & Canvas:** Card 7–9 ✅
- **Sprint 4 – Cloud Sync & Export:** Card 10–12 ✅
- **Sprint 5 – Hồ sơ đồ án:** Card 13 đóng gói ⏳ · Card 14 video demo ⏳ · Card 15 báo cáo ⏳ · Card 16 slide ⏳
- **Sprint 6 – Chạy thật luồng phiếu & đồng bộ:** Card 17–18 ✅ · Card 19 ⚠️ (còn build Android)
- **Sprint 7 – Danh mục tài sản thật:** Card 20, 22 ✅ · Card 21 ⚠️ (còn thử lưu tài sản khi mất mạng)
- **Sprint 8 – Hoàn thiện chức năng:** Card 23 ảnh minh chứng ✅ · Card 24 tự đồng bộ ✅ · Card 25 đối chiếu dữ liệu ✅
- **Sprint 9 – Tài khoản & nền tảng:** Card 26 đăng nhập ✅ · Card 27 Địa điểm & Cài đặt ✅ · Card 28 bản web ✅

## Hạn chế đã biết

- Mô hình chưa nhận ra vết nứt (điểm Vết nứt ~0,5% trên ảnh thử); các lớp khác đạt khoảng 57–74% trên máy thật.
- Mô hình float32 nặng 42 MB, mỗi khung mất 1,5–2,2 giây trên iPhone 11 Pro Max.
- Chưa build và kiểm thử trên Android (bản vá `mobile_scanner` mới có cho iOS).
- Tự đồng bộ chỉ chạy khi app đang mở (chưa dùng tác vụ nền iOS).
- Mã phiếu trên web đánh theo thứ tự trên đám mây nên có thể khác mã trên điện thoại.

---

## Quy trình Git

Mỗi thay đổi một commit theo Conventional Commits (`feat(card24): …`, `fix(ai): …`), làm trên nhánh tính năng và gộp vào `main` qua Pull Request ([#1](https://github.com/longtapdanhcode/DoAnCN2-test/pull/1) – Sprint 6–7, [#2](https://github.com/longtapdanhcode/DoAnCN2-test/pull/2) – Card 23–24, [#3](https://github.com/longtapdanhcode/DoAnCN2-test/pull/3) – Card 25, [#4](https://github.com/longtapdanhcode/DoAnCN2-test/pull/4) – Card 26–28).

Tài liệu kỹ thuật thêm: [PROJECT_AUDIT_REPORT.md](PROJECT_AUDIT_REPORT.md), [TECHNICAL_JUSTIFICATION.md](TECHNICAL_JUSTIFICATION.md), biên bản kiểm thử [docs/kiem-thu/](docs/kiem-thu/).

---

## Tác giả

- **Đồ án:** All-in-One Field Inventory & Edge AI Suite
- **Kho mã:** [longtapdanhcode/DoAnCN2-test](https://github.com/longtapdanhcode/DoAnCN2-test)
- **Giấy phép:** Phục vụ nghiên cứu và bảo vệ đồ án chuyên ngành. `third_party/mobile_scanner` giữ giấy phép BSD-3 gốc.
