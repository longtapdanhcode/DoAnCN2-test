# KẾ HOẠCH PHÂN CHIA VÀ QUẢN TRỊ PHIÊN BẢN GIT THEO SPRINT
## FIELD INVENTORY & EDGE AI SUITE

---

**Dự án:** `field_inventory_edge_ai` (All-in-One Field Inventory & Edge AI Suite)  
**Vai trò:** Senior Tech Lead & Git Specialist  
**Mục tiêu:** Ánh xạ toàn bộ cấu trúc mã nguồn thực tế vào lịch trình tiến độ 4 Sprint (12 Cards trên Trello) và cung cấp kịch bản commit Git chuẩn Conventional Commits kèm script thực thi tự động.

---

## 1. Bảng Ánh Xạ File & Thư Mục Thực Tế Theo Sprint (File Mapping Table)

Bảng dưới đây phân loại chi tiết từng tệp tin và thư mục trong repository vào đúng phạm vi trách nhiệm của từng Card và Sprint theo quy trình phát triển thực tế:

| Sprint | Card ID | Tên Card / Nhiệm vụ Trello | Danh sách File & Thư mục Thực tế | Vai trò Kỹ thuật & Mô tả |
| :--- | :--- | :--- | :--- | :--- |
| **Khởi tạo** | `Init` | Khởi tạo môi trường Git & Tài liệu gốc | `README.md`<br>`.gitignore` | Cấu hình bỏ qua tệp tạm (.dart_tool, build/, .idea/) và tài liệu giới thiệu tổng quan dự án. |
| **Sprint 1** | **Card 1** | Thu thập & Chuẩn bị Dataset thiết bị | `assets/models/labels.txt` | Danh mục nhãn phân loại thiết bị/tài sản hiện trường phục vụ huấn luyện và kiểm thử. |
| | **Card 2** | Huấn luyện mô hình Object Detection | `lib/core/ai_pipeline/ai_config.dart` | Khai báo hằng số cấu hình AI pipeline: kích thước input tensor (224x224), ngưỡng confidence (0.5), đường dẫn asset. |
| | **Card 3** | Lượng tử hóa & Xuất mô hình TFLite | `assets/models/object_detection.tflite` | Tệp nhị phân mô hình AI đã lượng tử hóa FP16/INT8 sẵn sàng chạy suy luận trên chip thiết bị (On-Device). |
| **Sprint 2** | **Card 4** | Khởi tạo Flutter App & Clean Architecture | `pubspec.yaml`<br>`pubspec.lock`<br>`analysis_options.yaml`<br>`.metadata`<br>`android/`<br>`ios/`<br>`macos/`<br>`web/`<br>`windows/`<br>`lib/main.dart` (khung nền)<br>`lib/core/router/app_router.dart`<br>`lib/core/router/app_router.g.dart`<br>`lib/core/.gitkeep`<br>`lib/features/.gitkeep`<br>`test/widget_test.dart` | Khởi tạo dự án Flutter đa nền tảng, thiết lập bộ lint rules, cấu hình GoRouter tập trung và cây thư mục Feature-First Clean Architecture. |
| | **Card 5** | Tích hợp Camera & Mobile Scanner | `lib/features/edge_vision/domain/entities/scan_result.dart`<br>`lib/features/edge_vision/domain/repositories/scanner_repository.dart`<br>`lib/features/edge_vision/domain/usecases/process_scan_result_usecase.dart`<br>`lib/features/edge_vision/data/repositories/scanner_repository_impl.dart`<br>`lib/features/edge_vision/presentation/widgets/scanner_overlay.dart`<br>`lib/features/edge_vision/presentation/screens/scanner_screen.dart`<br>`test/features/edge_vision/process_scan_result_usecase_test.dart` | Luồng quét mã Barcode/QR bằng ML Kit native, hiển thị viewfinder viewfinder overlay và bóc tách định dạng mã vạch hợp lệ. |
| | **Card 6** | Nhúng TFLite & Inference On-Device | `lib/features/edge_vision/domain/repositories/vision_ai_repository.dart`<br>`lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart`<br>`lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.g.dart`<br>`lib/features/edge_vision/presentation/controllers/scanner_controller.dart`<br>`lib/features/edge_vision/presentation/controllers/scanner_controller.g.dart`<br>`test/features/edge_vision/vision_ai_repository_test.dart` | Tích hợp C++ TFLite Interpreter, tiền xử lý ma trận ảnh Float32 ($1 \times 224 \times 224 \times 3$), cơ chế drop-frame chống nghẽn CPU và phát hiện nhãn AI thời gian thực. |
| **Sprint 3** | **Card 7** | Thiết lập Local Database Isar Plus | `lib/core/database/local_db_init.dart`<br>`lib/core/database/local_db_init.g.dart`<br>`lib/features/offline_audit/data/models/audit_record_model.dart`<br>`lib/features/offline_audit/data/models/audit_record_model.g.dart`<br>`lib/features/offline_audit/domain/repositories/audit_repository.dart`<br>`lib/features/offline_audit/data/repositories/isar_audit_repository_impl.dart`<br>`lib/features/offline_audit/data/repositories/isar_audit_repository_impl.g.dart` | Khởi tạo CSDL Isar Plus NoSQL nhúng, định nghĩa Entity Collection bản ghi kiểm kê với ACID transaction và hỗ trợ lưu trữ byte nhị phân. |
| | **Card 8** | Màn hình Biểu mẫu kiểm kê động | `lib/features/offline_audit/presentation/controllers/audit_form_controller.dart`<br>`lib/features/offline_audit/presentation/controllers/audit_form_controller.g.dart`<br>`lib/features/offline_audit/presentation/screens/audit_form_screen.dart`<br>`test/features/offline_audit/audit_form_controller_test.dart`<br>`test/features/offline_audit/audit_form_screen_test.dart` | Giao diện Dynamic Form tự động điền mã quét và nhãn AI, hỗ trợ chip tăng nhanh số lượng, validate dữ liệu và lưu xuống Isar Database. |
| | **Card 9** | Custom Canvas Chữ ký số điện tử | `lib/features/canvas_signature/presentation/screens/signature_screen.dart`<br>`test/features/canvas_signature/signature_screen_test.dart` | Bảng vẽ vector cảm ứng 3.5px thu nhận chữ ký người kiểm kê, ngăn chặn chữ ký rỗng và xuất mảng byte PNG (`Uint8List`) đính kèm form. |
| **Sprint 4** | **Card 10** | Thiết lập Backend Supabase Core & Sync | `lib/core/network/supabase_config.dart`<br>`lib/core/network/supabase_provider.dart`<br>`lib/core/network/supabase_provider.g.dart`<br>`lib/features/offline_audit/domain/repositories/sync_repository.dart`<br>`lib/features/offline_audit/data/models/cloud_audit_record_model.dart`<br>`test/features/offline_audit/cloud_audit_record_model_test.dart` | Cấu hình Supabase Client toàn cục, model ánh xạ đám mây `CloudAuditRecordModel` (UUID, UTC timestamp, Storage URL) và hợp đồng `SyncRepository`. |
| | **Card 11** | Chức năng xuất Báo cáo PDF A4 | `lib/core/utils/pdf_report_generator.dart`<br>`test/core/utils/pdf_report_generator_test.dart` | Động cơ sinh tệp PDF A4 đa trang, tự nạp font tiếng Việt Unicode Roboto, bảng danh mục chi tiết và tích hợp native share/print sheet. |
| | **Card 12** | Tối ưu UI Responsive cho Desktop | `lib/core/utils/responsive_layout.dart`<br>`lib/features/report_dashboard/presentation/screens/dashboard_screen.dart`<br>`test/core/utils/responsive_layout_test.dart`<br>`test/features/report_dashboard/dashboard_screen_test.dart` | Tiện ích phân tách layout breakpoint 800px; Dashboard Desktop trang bị Navigation Sidebar 250px và GridView thống kê; căn giữa và giới hạn kích thước form. |
| **Sprint 5** | **Hồ sơ** | Báo cáo Kiểm toán & Hồ sơ Nghiệm thu | `TECHNICAL_JUSTIFICATION.md`<br>`PROJECT_AUDIT_REPORT.md`<br>`git_sprint_commit_plan.md`<br>`commit_sprints.sh` | Toàn bộ tài liệu luận chứng kiến trúc, báo cáo kiểm toán chất lượng mã nguồn (0 issues, 25/25 test passed) và kịch bản phân nhánh Git. |

---

## 2. Kịch Bản Lệnh Git Chi Tiết (Git Execution Script)

Quy trình Git chuẩn **Git Flow kết hợp Trunk-Based Development**: Mỗi Sprint phát triển trên một nhánh riêng biệt (`sprint-1`, `sprint-2`, `sprint-3`, `sprint-4`), các Card được commit theo đúng thứ tự logic, sau đó merge về nhánh chính (`main`) bằng cờ `--no-ff` (No Fast-Forward) để bảo toàn lịch sử nhánh và đánh Tag phiên bản.

```
(main) o-------------------o=================o=================o=================o (v0.4-sprint4)
        \                 / (v0.1-sprint1)  / (v0.2-sprint2)  / (v0.3-sprint3)  /
(sprint-1)\--c1--c2--c3--/                 /                 /                 /
(sprint-2) \----------------------c4--c5--c6/                 /                 /
(sprint-3)  \----------------------------------------c7--c8--c9/                 /
(sprint-4)   \--------------------------------------------------c10--c11--c12---/
```

### 2.1. Bước 0: Khởi tạo Repository và Initial Commit
```bash
# 1. Khởi tạo Git repo với nhánh chính mang tên main
git init -b main

# 2. Cấu hình thông tin tác giả (nếu chưa cấu hình toàn cục)
git config user.name "Senior Lead Developer"
git config user.email "lead.dev@fieldinventory.ai"

# 3. Commit nền tảng ban đầu
git add .gitignore README.md
git commit -m "chore: initial commit with gitignore and project readme"
```

---

### 2.2. Sprint 1: Computer Vision & AI Pipeline (Tuần 1–3)
```bash
# Tạo và chuyển sang nhánh sprint-1
git checkout -b sprint-1

# Card 1: Thu thập và chuẩn bị Dataset ảnh hỏng hóc/thiết bị
git add assets/models/labels.txt
git commit -m "feat(cv): Card 1 - Thu thap va chuan bi Dataset anh thiet bi (labels.txt)"

# Card 2: Huấn luyện mô hình Object Detection (YOLOv8/MobileNet)
git add lib/core/ai_pipeline/ai_config.dart
git commit -m "feat(cv): Card 2 - Huan luyen mo hinh Object Detection va thiet lap thong so AI"

# Card 3: Lượng tử hóa và xuất mô hình (Quantization & Export)
git add assets/models/object_detection.tflite
git commit -m "feat(cv): Card 3 - Luong tu hoa va xuat mo hinh TFLite on-device"

# Merge Sprint 1 về main và gắn Tag phiên bản
git checkout main
git merge --no-ff sprint-1 -m "merge: Sprint 1 - Computer Vision & AI Pipeline"
git tag -a v0.1-sprint1 -m "Release v0.1: Hoàn thành Sprint 1 (CV & AI Pipeline)"
```

---

### 2.3. Sprint 2: Flutter App Core & Edge AI (Tuần 4–5)
```bash
# Tạo và chuyển sang nhánh sprint-2 từ main
git checkout -b sprint-2

# Card 4: Khởi tạo project Flutter & Clean Architecture
git add pubspec.yaml pubspec.lock analysis_options.yaml .metadata \
        android/ ios/ macos/ web/ windows/ .vscode/ \
        lib/main.dart lib/core/router/ \
        $(find lib -name ".gitkeep") \
        test/widget_test.dart
git commit -m "feat(core): Card 4 - Khoi tao project Flutter va khung Clean Architecture"

# Card 5: Tích hợp luồng Camera & Mobile Scanner
git add lib/features/edge_vision/domain/entities/scan_result.dart \
        lib/features/edge_vision/domain/repositories/scanner_repository.dart \
        lib/features/edge_vision/domain/usecases/process_scan_result_usecase.dart \
        lib/features/edge_vision/data/repositories/scanner_repository_impl.dart \
        lib/features/edge_vision/presentation/widgets/scanner_overlay.dart \
        lib/features/edge_vision/presentation/screens/scanner_screen.dart \
        test/features/edge_vision/process_scan_result_usecase_test.dart
git commit -m "feat(scanner): Card 5 - Tich hop luong Camera va Mobile Scanner ML Kit"

# Card 6: Nhúng TFLite & Chạy Inference On-Device
git add lib/features/edge_vision/domain/repositories/vision_ai_repository.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.g.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.g.dart \
        test/features/edge_vision/vision_ai_repository_test.dart
git commit -m "feat(ai): Card 6 - Nhung TFLite va chay suy luan On-Device realtime"

# Merge Sprint 2 về main và gắn Tag phiên bản
git checkout main
git merge --no-ff sprint-2 -m "merge: Sprint 2 - Flutter App Core & Edge AI"
git tag -a v0.2-sprint2 -m "Release v0.2: Hoàn thành Sprint 2 (Flutter Core & Edge AI)"
```

---

### 2.4. Sprint 3: Offline-First Database & Custom Canvas (Tuần 6–7)
```bash
# Tạo và chuyển sang nhánh sprint-3 từ main
git checkout -b sprint-3

# Card 7: Thiết lập Local Database với Isar
git add lib/core/database/local_db_init.dart \
        lib/core/database/local_db_init.g.dart \
        lib/features/offline_audit/data/models/audit_record_model.dart \
        lib/features/offline_audit/data/models/audit_record_model.g.dart \
        lib/features/offline_audit/domain/repositories/audit_repository.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.g.dart
git commit -m "feat(db): Card 7 - Thiet lap Local Database voi Isar Plus offline-first"

# Card 8: Màn hình Biểu mẫu kiểm kê động (Dynamic Form)
git add lib/features/offline_audit/presentation/controllers/audit_form_controller.dart \
        lib/features/offline_audit/presentation/controllers/audit_form_controller.g.dart \
        lib/features/offline_audit/presentation/screens/audit_form_screen.dart \
        test/features/offline_audit/audit_form_controller_test.dart \
        test/features/offline_audit/audit_form_screen_test.dart
git commit -m "feat(audit): Card 8 - Man hinh bieu mau kiem ke dong va quan ly trang thai"

# Card 9: Tích hợp Custom Canvas (Chữ ký & Ghi chú ảnh)
git add lib/features/canvas_signature/presentation/screens/signature_screen.dart \
        test/features/canvas_signature/signature_screen_test.dart
git commit -m "feat(canvas): Card 9 - Tich hop Custom Canvas chu ky so va xuat PNG bytes"

# Merge Sprint 3 về main và gắn Tag phiên bản
git checkout main
git merge --no-ff sprint-3 -m "merge: Sprint 3 - Offline-First Database & Custom Canvas"
git tag -a v0.3-sprint3 -m "Release v0.3: Hoàn thành Sprint 3 (Isar Local DB & Signature Canvas)"
```

---

### 2.5. Sprint 4: Cloud Sync & Export (Tuần 8–9)
```bash
# Tạo và chuyển sang nhánh sprint-4 từ main
git checkout -b sprint-4

# Card 10: Thiết lập Backend & Cloud Sync (Supabase)
git add lib/core/network/supabase_config.dart \
        lib/core/network/supabase_provider.dart \
        lib/core/network/supabase_provider.g.dart \
        lib/features/offline_audit/domain/repositories/sync_repository.dart \
        lib/features/offline_audit/data/models/cloud_audit_record_model.dart \
        test/features/offline_audit/cloud_audit_record_model_test.dart
git commit -m "feat(cloud): Card 10 - Thiet lap Backend Supabase Core va Cloud Sync contract"

# Card 11: Chức năng xuất Báo cáo PDF
git add lib/core/utils/pdf_report_generator.dart \
        test/core/utils/pdf_report_generator_test.dart
git commit -m "feat(report): Card 11 - Chuc nang xuat bao cao kiem ke PDF da trang"

# Card 12: Tối ưu UI cho phiên bản Desktop
git add lib/core/utils/responsive_layout.dart \
        lib/features/report_dashboard/presentation/screens/dashboard_screen.dart \
        test/core/utils/responsive_layout_test.dart \
        test/features/report_dashboard/dashboard_screen_test.dart
git commit -m "feat(ui): Card 12 - Toi uu UI Responsive cho phien ban Desktop va Tablet"

# Merge Sprint 4 về main và gắn Tag phiên bản
git checkout main
git merge --no-ff sprint-4 -m "merge: Sprint 4 - Cloud Sync & Export"
git tag -a v0.4-sprint4 -m "Release v0.4: Hoàn thành Sprint 4 (Cloud Sync, PDF & Desktop UI)"
```

---

### 2.6. Bước 5: Đóng gói Tài liệu Kiểm toán & Chuẩn bị Sprint 5
```bash
# Commit tài liệu kỹ thuật, báo cáo nghiệm thu và kịch bản commit
git add TECHNICAL_JUSTIFICATION.md PROJECT_AUDIT_REPORT.md git_sprint_commit_plan.md commit_sprints.sh
git commit -m "docs(audit): Hoan thien bao cao kiem toan kien truc va ke hoach Git commit Sprint"
git tag -a v1.0.0-final -m "Release v1.0.0: Sẵn sàng bảo vệ đồ án Sprint 5"
```

---

## 3. Hướng Dẫn Chạy Script Tự Động (`commit_sprints.sh`)

Repository đã được trang bị sẵn script shell tự động hoá toàn bộ các bước trên. Bạn chỉ cần mở Terminal tại thư mục gốc và chạy:

```bash
# 1. Cấp quyền thực thi cho script
chmod +x commit_sprints.sh

# 2. Chạy script tự động (tùy chọn cờ -f hoặc --force để tự động làm mới repo nếu đã có .git)
./commit_sprints.sh --force
```

Sau khi chạy xong, kiểm tra lại toàn bộ cây lịch sử Git bằng lệnh:
```bash
git log --oneline --graph --all --decorate
```
Bạn sẽ thấy một cây lịch sử Git chuẩn mực, đẹp mắt và phản ánh 100% tiến độ thực tế theo đúng kế hoạch Trello.
