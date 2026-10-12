# Field Inventory & Edge AI Suite
### Giải Pháp Kiểm Kê Tài Sản & Thiết Bị Hiện Trường Tích Hợp Trí Tuệ Nhân Tạo On-Device

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_v3-2F74C0)](https://riverpod.dev)
[![Database](https://img.shields.io/badge/Local_DB-Isar_Plus-4A154B)](https://isar.dev)
[![Edge AI](https://img.shields.io/badge/Edge_AI-TFLite_On--Device-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![Backend](https://img.shields.io/badge/BaaS-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![Clean Architecture](https://img.shields.io/badge/Architecture-Feature--First_Clean-green)](#kiến-trúc-hệ-thống)
[![Tests](https://img.shields.io/badge/Tests-25%2F25_Passed-success)](test/)
[![Analysis](https://img.shields.io/badge/Analyze-0_Issues-brightgreen)](#chất-lượng-mã-nguồn)

---

## 📖 Giới Thiệu Dự Án

**Field Inventory & Edge AI Suite** là hệ thống phần mềm toàn diện hỗ trợ kỹ thuật viên và kiểm kê viên ghi nhận, phân loại và quản lý tài sản, vật tư thiết bị trực tiếp ngoài hiện trường. Ứng dụng được thiết kế theo triết lý **Offline-First**, hoạt động bền bỉ trong các môi trường khắc nghiệt không có kết nối Internet (hầm cáp, kho bãi vùng sâu, nhà máy điện), đồng thời khai thác sức mạnh của **Trí tuệ nhân tạo biên (Edge AI)** để phân loại vật tư tức thời trên thiết bị mà không cần truyền tải hình ảnh lên đám mây.

---

## ✨ Tính Năng Nổi Bật

- 📷 **Camera Stream & Quét Mã Siêu Tốc**: Quét mã vạch 1D và QR Code tốc độ cao với ML Kit, tích hợp khung nhắm mục tiêu laser và điều khiển đèn flash chiếu sáng.
- 🧠 **On-Device Edge Vision (TensorFlow Lite)**: Suy luận nhận diện thiết bị/hỏng hóc trực tiếp trên chip thiết bị với cơ chế drop-frame bảo vệ CPU/pin.
- 💾 **Lưu Trữ Ngoại Tuyến (Isar Plus NoSQL)**: Ghi dữ liệu tức thì với giao dịch ACID, lưu trữ nhị phân trực tiếp ảnh chữ ký không qua chuyển đổi trung gian.
- 📝 **Dynamic Inventory Form**: Biểu mẫu kiểm kê động, tự động nhận diện thông tin quét, nút điều chỉnh số lượng nhanh (+1, +5, +10) và xác thực dữ liệu chặt chẽ.
- ✍️ **Custom Canvas Chữ Ký Số**: Bảng vẽ cảm ứng vector 3.5px chống rung, kiểm soát chống chữ ký rỗng và xuất ảnh PNG bytes đính kèm hồ sơ kiểm kê.
- 📄 **Xuất Báo Cáo PDF Chuẩn A4**: Động cơ sinh tệp PDF đa trang, hỗ trợ font Unicode tiếng Việt, bảng biểu tổng hợp số lượng và tích hợp in ấn / chia sẻ qua AirDrop, Email.
- 🖥️ **Responsive Layout Đa Nền Tảng**: Tối ưu hiển thị cho cả Di động (Mobile < 800px) và Máy tính bảng / Máy tính bàn (Desktop Sidebar >= 800px trên macOS, Windows).
- ☁️ **Đồng Bộ Đám Mây (Supabase)**: Khung đồng bộ dữ liệu hai chiều và lưu trữ Storage an toàn khi có mạng trở lại.

---

## 🏛️ Kiến Trúc Hệ Thống (Feature-First Clean Architecture)

Dự án áp dụng mô hình phân tầng nghiêm ngặt nhằm đảm bảo tính mở rộng, dễ kiểm thử và độc lập giữa các thành phần:

```
lib/
├── core/                                    # Tầng dùng chung toàn hệ thống
│   ├── ai_pipeline/                         # Cấu hình tensor input & threshold AI
│   ├── database/                            # Khởi tạo Isar Local Database
│   ├── network/                             # Cấu hình Supabase Client & Provider
│   ├── router/                              # Định tuyến khai báo GoRouter tập trung
│   └── utils/                               # Engine tiện ích (PDF Generator, Responsive Layout)
├── features/                                # Các phân hệ nghiệp vụ độc lập
│   ├── edge_vision/                         # Module: Quét mã & Phân tích Edge AI
│   │   ├── data/                            # Repository Implementations & Datasources
│   │   ├── domain/                          # Entities, Repository Interfaces & Use Cases
│   │   └── presentation/                    # UI Screens, Widgets & Riverpod Controllers
│   ├── offline_audit/                       # Module: Biểu mẫu kiểm kê & CSDL Isar
│   │   ├── data/models/                     # Isar Collection & Cloud Models
│   │   ├── domain/repositories/             # Contracts kho lưu trữ và đồng bộ
│   │   └── presentation/                    # Màn hình Form động & Controller
│   ├── canvas_signature/                    # Module: Chữ ký số điện tử
│   │   └── presentation/screens/            # Bảng vẽ cảm ứng & xuất PNG bytes
│   └── report_dashboard/                    # Module: Bảng điều khiển & Báo cáo
│       └── presentation/screens/            # Responsive Dashboard (Mobile & Desktop)
└── main.dart                                # Điểm khởi động ứng dụng
```

---

## 🛠️ Công Nghệ & Thư Viện Cốt Lõi

| Thư viện | Phiên bản | Vai trò & Lý do lựa chọn kỹ thuật |
| :--- | :---: | :--- |
| **`isar_plus`** | `^1.3.9` | CSDL nhúng NoSQL tốc độ vượt trội so với SQLite, hỗ trợ lưu trữ trực tiếp mảng byte nhị phân `List<int>`. |
| **`flutter_riverpod`** | `^3.4.3` | Quản trị State & DI compile-time safe, tách rời logic khỏi UI, hỗ trợ auto-dispose và mock test hoàn hảo. |
| **`go_router`** | `^18.0.2` | Định tuyến khai báo, hỗ trợ truyền nhận dữ liệu payload 2 chiều an toàn kiểu dữ liệu. |
| **`mobile_scanner`** | `^7.4.2` | Quét mã ML Kit native phần cứng, cho phép trích xuất camera frame texture. |
| **`tflite_flutter`** | `^0.12.1` | Nhúng C++ TensorFlow Lite runtime trực tiếp vào ứng dụng chạy inference on-device. |
| **`signature`** | `^6.4.0` | Thu nhận chữ ký số vector thời gian thực, xuất định dạng ảnh PNG độ phân giải cao. |
| **`pdf` & `printing`** | `^3.13.1` / `^5.15.1` | Tạo tệp PDF A4 vector, tự nạp font tiếng Việt Unicode Roboto, tích hợp native share/print sheet. |
| **`supabase_flutter`** | `^2.18.0` | Backend-as-a-Service (PostgreSQL, Storage, Auth, Realtime). |
| **`flex_color_scheme`** | `^9.0.0` | Hệ thống thiết kế Material 3 hiện đại, độ tương phản cao cho môi trường hiện trường. |

---

## 🗺️ Tiến Độ Dự Án Theo Sprint (Trello Roadmap)

Dự án được triển khai theo quy trình Agile/Scrum qua 5 Sprint hoàn chỉnh:

### 🔹 Sprint 1: Computer Vision & AI Pipeline (Tuần 1–3)
- [x] **Card 1**: Thu thập và chuẩn bị Dataset ảnh hỏng hóc/thiết bị (`assets/models/labels.txt`).
- [x] **Card 2**: Huấn luyện mô hình Object Detection MobileNet/YOLOv8 (`lib/core/ai_pipeline/ai_config.dart`).
- [x] **Card 3**: Lượng tử hóa và xuất mô hình TFLite on-device (`assets/models/object_detection.tflite`).

### 🔹 Sprint 2: Flutter App Core & Edge AI (Tuần 4–5)
- [x] **Card 4**: Khởi tạo project Flutter đa nền tảng & cấu trúc Clean Architecture (`pubspec.yaml`, `lib/core/router/`).
- [x] **Card 5**: Tích hợp luồng Camera & Mobile Scanner ML Kit (`features/edge_vision/`).
- [x] **Card 6**: Nhúng TFLite & chạy suy luận On-Device realtime kèm cơ chế drop-frame chống nghẽn CPU.

### 🔹 Sprint 3: Offline-First Database & Custom Canvas (Tuần 6–7)
- [x] **Card 7**: Thiết lập Local Database với Isar Plus (`features/offline_audit/data/models/audit_record_model.dart`).
- [x] **Card 8**: Xây dựng màn hình Biểu mẫu kiểm kê động Dynamic Form (`audit_form_screen.dart`).
- [x] **Card 9**: Tích hợp Custom Canvas chữ ký số và pipeline xuất mảng byte PNG (`signature_screen.dart`).

### 🔹 Sprint 4: Cloud Sync & Export (Tuần 8–9)
- [x] **Card 10**: Thiết lập Backend Supabase Core & Sync model (`core/network/supabase_config.dart`).
- [x] **Card 11**: Chức năng xuất Báo cáo kiểm kê PDF chuẩn A4 đa trang (`core/utils/pdf_report_generator.dart`).
- [x] **Card 12**: Tối ưu UI Responsive cho Desktop (Sidebar 250px, GridView thống kê, Breakpoint 800px).

### 🔹 Sprint 5: Hardening & Bảo Vệ Đồ Án (Tuần 10)
- [x] **Card 13**: Hoàn thiện báo cáo kiểm toán kiến trúc [PROJECT_AUDIT_REPORT.md](PROJECT_AUDIT_REPORT.md) & [TECHNICAL_JUSTIFICATION.md](TECHNICAL_JUSTIFICATION.md).
- [ ] **Card 14**: Kịch bản chạy thực địa và Video Demo sản phẩm đa nền tảng.
- [ ] **Card 15**: Hoàn tất tài liệu thuyết trình và nghiệm thu đồ án tốt nghiệp.

---

## 🌿 Quản Trị Phiên Bản Git (Git Flow & Conventional Commits)

Toàn bộ lịch sử mã nguồn được tổ chức theo mô hình phân nhánh chuẩn **Git Flow kết hợp Trunk-Based Development**:

```text
* 406364e (HEAD -> main, tag: v1.0.0-final) docs(audit): Hoan thien bao cao kiem toan kien truc va ke hoach Git commit Sprint
*   85e643f (tag: v0.4-sprint4) merge: Sprint 4 - Cloud Sync & Export
|\  
| * 5d2367f (sprint-4) feat(ui): Card 12 - Toi uu UI Responsive cho phien ban Desktop va Tablet
| * 3da2085 feat(report): Card 11 - Chuc nang xuat bao cao kiem ke PDF da trang chuan A4
| * a9881d9 feat(cloud): Card 10 - Thiet lap Backend Supabase Core va Cloud Sync contract
|/  
*   05e8490 (tag: v0.3-sprint3) merge: Sprint 3 - Offline-First Database & Custom Canvas
|\  
| * 634d07d (sprint-3) feat(canvas): Card 9 - Tich hop Custom Canvas chu ky so va xuat PNG bytes
| * aca99fa feat(audit): Card 8 - Man hinh bieu mau kiem ke dong va quan ly trang thai
| * af3cd02 feat(db): Card 7 - Thiet lap Local Database voi Isar Plus offline-first
|/  
*   560fffa (tag: v0.2-sprint2) merge: Sprint 2 - Flutter App Core & Edge AI
|\  
| * da313a2 (sprint-2) feat(ai): Card 6 - Nhung TFLite va chay suy luan On-Device realtime
| * 40a3f89 feat(scanner): Card 5 - Tich hop luong Camera va Mobile Scanner ML Kit
| * 9ec91cb feat(core): Card 4 - Khoi tao project Flutter va khung Clean Architecture
|/  
*   56456c9 (tag: v0.1-sprint1) merge: Sprint 1 - Computer Vision & AI Pipeline
|\  
| * c71edf7 (sprint-1) feat(cv): Card 3 - Luong tu hoa va xuat mo hinh TFLite on-device
| * f48dfe5 feat(cv): Card 2 - Huan luyen mo hinh Object Detection va thiet lap thong so AI
| * 266ef8a feat(cv): Card 1 - Thu thap va chuan bi Dataset anh thiet bi (labels.txt)
|/  
* 555ae83 chore: initial commit with gitignore and project readme
```

### Các Mốc Phiên Bản (Git Tags):
- 🏷️ `v0.1-sprint1`: Hoàn thành Sprint 1 (Computer Vision & AI Pipeline).
- 🏷️ `v0.2-sprint2`: Hoàn thành Sprint 2 (Flutter Core & Edge AI).
- 🏷️ `v0.3-sprint3`: Hoàn thành Sprint 3 (Isar Local Database & Custom Canvas).
- 🏷️ `v0.4-sprint4`: Hoàn thành Sprint 4 (Cloud Sync, PDF Engine & Responsive UI).
- 🏷️ `v1.0.0-final`: Hoàn thiện tài liệu nghiệm thu kỹ thuật và đóng gói đồ án.

> Chi tiết quy trình và script tự động được mô tả tại [git_sprint_commit_plan.md](git_sprint_commit_plan.md) và [commit_sprints.sh](commit_sprints.sh).

---

## 📊 Chỉ Số Chất Lượng & Kiểm Thử (Quality Assurance)

```
======================================================================
CHỈ SỐ ĐO LƯỜNG CHẤT LƯỢNG MÃ NGUỒN (CODE QUALITY METRICS)
======================================================================
• Trạng thái Flutter Analyze : 0 issues found (Clean Code)
• Kết quả Kiểm thử (Tests)   : 25 / 25 test cases PASSED (100%)
• Số lượng bộ kiểm thử       : 10 test files
• Quy mô mã nguồn viết tay   : 3,654 dòng (lib/)
• Quy mô mã nguồn sinh tự động: 1,916 dòng (.g.dart)
• Quy mô mã nguồn kiểm thử   : 633 dòng (test/)
======================================================================
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu Cầu Môi Trường
- Flutter SDK: `>= 3.13.4`
- Dart SDK: `>= 3.13.4`
- Thiết bị thử nghiệm: Android 8.0+ / iOS 14.0+ / macOS 11.0+ / Windows 10+

### Các Bước Cài Đặt
```bash
# 1. Clone repository
git clone https://github.com/longtapdanhcode/DoAnCN2-test.git
cd DoAnCN2-test

# 2. Cài đặt các thư viện phụ thuộc
flutter pub get

# 3. Chạy bộ kiểm thử tự động
flutter test

# 4. Kiểm tra mã nguồn với linter
flutter analyze

# 5. Khởi chạy ứng dụng trên thiết bị
flutter run
```

---

## 👥 Tác Giả & Bản Quyền

- **Đồ án:** All-in-One Field Inventory & Edge AI Suite
- **Kho lưu trữ:** [longtapdanhcode/DoAnCN2-test](https://github.com/longtapdanhcode/DoAnCN2-test.git)
- **Giấy phép:** Phục vụ nghiên cứu và bảo vệ đồ án chuyên ngành.
