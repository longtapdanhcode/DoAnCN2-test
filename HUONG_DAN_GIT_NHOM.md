# HƯỚNG DẪN GIT CHO NHÓM (TV1 – TV2 – TV3)

Repo: https://github.com/longtapdanhcode/Finalterm_DANENTANG.git
Nhánh có sẵn: `main` (ổn định), `develop` (tích hợp). Cả hai hiện chỉ chứa khung dự án (Sprint 0).

## Quy tắc chung
1. Mỗi Card làm trên **1 nhánh riêng** tách từ `develop`: `feature/sprint<N>-card<M>-tv<K>`.
2. **Chỉ `git add` từng file cụ thể** liệt kê bên dưới. KHÔNG dùng `git add .` hoặc `git add -A`.
3. Push nhánh rồi tạo Pull Request vào `develop` (không push thẳng `develop`/`main`).
4. Chỉ bắt đầu Sprint N+1 sau khi PR của Sprint N đã được merge vào `develop`. Trong cùng Sprint, Card sau cần Card trước (ví dụ Card 6 cần Card 5) thì chờ merge rồi `git pull`.
5. Trước mỗi commit kiểm tra: `git diff --cached --name-only` và `git status --short`.

## Lần đầu (mỗi thành viên)
```bash
git clone https://github.com/longtapdanhcode/Finalterm_DANENTANG.git
cd Finalterm_DANENTANG
git config user.name "Tên của bạn"
git config user.email "email@cua-ban.com"
git checkout develop
```
> Nếu máy đã có sẵn code thì chép đúng các file được giao vào đúng đường dẫn trong repo vừa clone.

## Mẫu lệnh cho MỖI Card
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint<N>-card<M>-tv<K>
git add <file 1> <file 2> ...
git diff --cached --name-only        # kiểm tra lại
git commit -m "<message>"
git push -u origin feature/sprint<N>-card<M>-tv<K>
# -> Lên GitHub tạo Pull Request: base = develop
```

## Bảng phân công

| Sprint | Card | Người làm | Nội dung |
|---|---|---|---|
| 1 | 1 | TV1 | Dataset / labels |
| 1 | 2 | TV2 | Cấu hình AI pipeline |
| 1 | 3 | TV3 | Mô hình TFLite |
| 2 | 4 | TV1 | Flutter app core + router |
| 2 | 5 | TV2 | Camera & Mobile Scanner |
| 2 | 6 | TV3 | TFLite inference (cần Card 5 đã merge) |
| 3 | 7 | TV1 | Local DB Isar |
| 3 | 8 | TV2 | Form kiểm kê (cần Card 5, 7 đã merge) |
| 3 | 9 | TV3 | Canvas chữ ký |
| 4 | 10 | TV1 | Supabase core & sync contract |
| 4 | 11 | TV2 | Xuất PDF |
| 4 | 12 | TV3 | UI Responsive / Dashboard |
| 5 | Hồ sơ | TV1 | Tài liệu kiểm toán |

(Có thể đổi người, chỉ cần giữ nguyên danh sách file của từng Card.)

---

## SPRINT 1 – Computer Vision & AI Pipeline

### TV1 – Card 1
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint1-card1-tv1
git add assets/models/labels.txt
git commit -m "feat(cv): Card 1 - Thu thap va chuan bi Dataset anh thiet bi (labels.txt)"
git push -u origin feature/sprint1-card1-tv1
```

### TV2 – Card 2
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint1-card2-tv2
git add lib/core/ai_pipeline/ai_config.dart
git commit -m "feat(cv): Card 2 - Thiet lap cau hinh AI pipeline cho Object Detection"
git push -u origin feature/sprint1-card2-tv2
```

### TV3 – Card 3
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint1-card3-tv3
git add assets/models/object_detection.tflite
git commit -m "feat(cv): Card 3 - Luong tu hoa va xuat mo hinh TFLite on-device"
git push -u origin feature/sprint1-card3-tv3
```

---

## SPRINT 2 – Flutter App Core & Edge AI

### TV1 – Card 4
(`pubspec.yaml`, `android/`, `ios/`... đã có từ Sprint 0, chỉ còn các file dưới)
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint2-card4-tv1
git add lib/main.dart \
        lib/core/router/app_router.dart \
        lib/core/router/app_router.g.dart \
        test/widget_test.dart
git commit -m "feat(core): Card 4 - Khoi tao project Flutter va khung Clean Architecture"
git push -u origin feature/sprint2-card4-tv1
```

### TV2 – Card 5
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint2-card5-tv2
git add lib/features/edge_vision/domain/entities/scan_result.dart \
        lib/features/edge_vision/domain/repositories/scanner_repository.dart \
        lib/features/edge_vision/domain/usecases/process_scan_result_usecase.dart \
        lib/features/edge_vision/data/repositories/scanner_repository_impl.dart \
        lib/features/edge_vision/presentation/widgets/scanner_overlay.dart \
        lib/features/edge_vision/presentation/screens/scanner_screen.dart \
        test/features/edge_vision/process_scan_result_usecase_test.dart
git commit -m "feat(scanner): Card 5 - Tich hop luong Camera va Mobile Scanner ML Kit"
git push -u origin feature/sprint2-card5-tv2
```

### TV3 – Card 6 (chờ Card 5 merge rồi mới tạo nhánh)
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint2-card6-tv3
git add lib/features/edge_vision/domain/repositories/vision_ai_repository.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart \
        lib/features/edge_vision/data/repositories/tflite_vision_repository_impl.g.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.dart \
        lib/features/edge_vision/presentation/controllers/scanner_controller.g.dart \
        test/features/edge_vision/vision_ai_repository_test.dart
git commit -m "feat(ai): Card 6 - Nhung TFLite va chay suy luan On-Device realtime"
git push -u origin feature/sprint2-card6-tv3
```

---

## SPRINT 3 – Offline-First Database & Custom Canvas

### TV1 – Card 7
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint3-card7-tv1
git add lib/core/database/local_db_init.dart \
        lib/core/database/local_db_init.g.dart \
        lib/features/offline_audit/data/models/audit_record_model.dart \
        lib/features/offline_audit/data/models/audit_record_model.g.dart \
        lib/features/offline_audit/domain/repositories/audit_repository.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.dart \
        lib/features/offline_audit/data/repositories/isar_audit_repository_impl.g.dart
git commit -m "feat(db): Card 7 - Thiet lap Local Database voi Isar Plus offline-first"
git push -u origin feature/sprint3-card7-tv1
```

### TV2 – Card 8 (chờ Card 7 merge)
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint3-card8-tv2
git add lib/features/offline_audit/presentation/controllers/audit_form_controller.dart \
        lib/features/offline_audit/presentation/controllers/audit_form_controller.g.dart \
        lib/features/offline_audit/presentation/screens/audit_form_screen.dart \
        test/features/offline_audit/audit_form_controller_test.dart \
        test/features/offline_audit/audit_form_screen_test.dart
git commit -m "feat(audit): Card 8 - Man hinh bieu mau kiem ke dong va quan ly trang thai"
git push -u origin feature/sprint3-card8-tv2
```

### TV3 – Card 9
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint3-card9-tv3
git add lib/features/canvas_signature/presentation/screens/signature_screen.dart \
        test/features/canvas_signature/signature_screen_test.dart
git commit -m "feat(canvas): Card 9 - Tich hop Custom Canvas chu ky so va xuat PNG bytes"
git push -u origin feature/sprint3-card9-tv3
```

---

## SPRINT 4 – Cloud Sync & Export

### TV1 – Card 10
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint4-card10-tv1
git add lib/core/network/supabase_config.dart \
        lib/core/network/supabase_provider.dart \
        lib/core/network/supabase_provider.g.dart \
        lib/features/offline_audit/domain/repositories/sync_repository.dart \
        lib/features/offline_audit/data/models/cloud_audit_record_model.dart \
        test/features/offline_audit/cloud_audit_record_model_test.dart
git commit -m "feat(cloud): Card 10 - Thiet lap Backend Supabase Core va Cloud Sync contract"
git push -u origin feature/sprint4-card10-tv1
```

### TV2 – Card 11
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint4-card11-tv2
git add lib/core/utils/pdf_report_generator.dart \
        test/core/utils/pdf_report_generator_test.dart
git commit -m "feat(report): Card 11 - Chuc nang xuat bao cao kiem ke PDF da trang"
git push -u origin feature/sprint4-card11-tv2
```

### TV3 – Card 12
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint4-card12-tv3
git add lib/core/utils/responsive_layout.dart \
        lib/features/report_dashboard/presentation/screens/dashboard_screen.dart \
        test/core/utils/responsive_layout_test.dart \
        test/features/report_dashboard/dashboard_screen_test.dart
git commit -m "feat(ui): Card 12 - Toi uu UI Responsive cho phien ban Desktop va Tablet"
git push -u origin feature/sprint4-card12-tv3
```

> Lưu ý Sprint 4: `supabase_sync_repository_impl.dart`, `sync_controller.dart` (và các file `.g.dart` đi kèm) cũng thuộc phần Sync. Thêm vào commit Card 10 (TV1) nếu nhóm muốn có đủ:
> `lib/features/offline_audit/data/repositories/supabase_sync_repository_impl.dart(.g.dart)`, `lib/features/offline_audit/presentation/controllers/sync_controller.dart(.g.dart)`.

---

## SPRINT 5 – Hồ sơ (TV1)
```bash
git checkout develop && git pull origin develop
git checkout -b feature/sprint5-docs-tv1
git add README.md TECHNICAL_JUSTIFICATION.md PROJECT_AUDIT_REPORT.md
git commit -m "docs(audit): Hoan thien tai lieu kien truc va bao cao kiem toan"
git push -u origin feature/sprint5-docs-tv1
```

## Phát hành (người phụ trách repo, sau khi mọi Sprint đã vào `develop`)
```bash
git checkout main && git pull origin main
git merge --no-ff develop -m "merge: release from develop"
git push origin main
```

## Gặp lỗi thường gặp
- `git push` bị từ chối → `git pull --rebase origin develop` rồi push lại.
- Lỡ `git add` nhầm file → `git restore --staged <file>`.
- Không có gì để commit → kiểm tra file đã nằm đúng đường dẫn chưa (`git status`).
