# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Dự án

Fieldline — app Flutter kiểm kê tài sản hiện trường (đồ án cuối kỳ). App hiện trường (iOS/Android/macOS) quét QR/barcode, chạy mô hình YOLOv8s TFLite ngay trên máy, lập phiếu kiểm kê ngoại tuyến bằng Isar, ký xác nhận, chụp ảnh minh chứng rồi đồng bộ lên Supabase. **Bản web là trung tâm quản lý**, đọc/ghi thẳng trên Supabase (không Isar, không camera, không AI). README.md là tài liệu chính về tính năng và cài đặt. Comment trong code, tài liệu và commit message đều viết bằng tiếng Việt.

## Lệnh thường dùng

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # sinh lại *.g.dart khi sửa @riverpod / model Isar
flutter analyze
flutter test                                               # chạy toàn bộ test
flutter test test/features/offline_audit/auto_sync_test.dart       # một file
flutter test --plain-name "một phần tên test"                      # một test
flutter run                  # chế độ hiện trường (mobile/macOS)
flutter run -d chrome        # bản web quản lý
flutter build apk --release
```

- Các file sinh tự động `*.g.dart` **được commit** vào repo; sửa code có annotation thì chạy lại build_runner và commit kèm.
- `lib/core/network/supabase_config.dart` nằm trong `.gitignore`, tạo từ `supabase_config.dart.example`. Để trống app vẫn khởi động, nhưng đăng nhập là bắt buộc.
- iOS: Impeller đã tắt trong `Info.plist` (tránh màn camera bị đen); camera và AI cần máy thật.

## Kiến trúc

Clean Architecture chia theo feature: `lib/features/<feature>/{domain,data,presentation}`. Phần dùng chung nằm ở `lib/core/` (router, theme, khởi tạo Isar, provider Supabase, trạng thái mạng, sinh PDF, khung điều hướng `FieldlineShell`).

### Hai chế độ app trên cùng một mã nguồn
Đây là thiết kế xuyên suốt quan trọng nhất, cần đọc các file sau cùng nhau:
- `lib/main.dart`: web → `ProviderScope(overrides: consoleOverrides())`, không mở Isar; mobile → mở Isar và override `isarInstanceProvider`.
- `lib/core/platform/app_mode.dart`: `AppMode.field` / `AppMode.console` (`appModeProvider`, test có thể override) và `fieldOnlyPaths` (`/scanner`, `/audit-form`, `/signature`, `/sync`).
- `lib/core/router/app_router.dart`: GoRouter có auth redirect, ở chế độ console thì chuyển các route chỉ dành cho hiện trường về `/`, dùng `ShellRoute` cho khung chính.
- `lib/features/cloud_console/console_overrides.dart`: thay `auditRecordsProvider` (tải lại từ Supabase mỗi phút), `evidencePhotoStoreProvider` (ảnh theo URL) và `assetCatalogRepositoryProvider` (repo cloud), nhờ đó các màn Tổng quan / Tài sản / Báo cáo / Địa điểm / Cài đặt dùng lại nguyên trên web.
- `edge_vision/data/repositories/vision_ai_providers.dart` dùng conditional export (`dart.library.js_interop`) để thay repository TFLite bằng bản báo "không hỗ trợ" trên web (web không có `dart:ffi`).

Khi thêm màn hình hoặc provider dùng cho cả hai nền tảng, hãy đưa nguồn dữ liệu vào một provider mà `consoleOverrides()` thay được, thay vì rẽ nhánh `kIsWeb` trong widget.

### Phiếu kiểm kê offline-first và đồng bộ (`features/offline_audit`)
- Mọi phiếu được ghi vào Isar (`AuditRecordModel`) trước. Phiếu chưa ký là **bản nháp**: không bao giờ đồng bộ, không vào báo cáo.
- `SyncController` đẩy các phiếu đã ký mà chưa đồng bộ lên Supabase (bảng `audit_records`, bucket `signatures` / `evidence`). `AutoSyncController` chạy khi trạng thái mạng thay đổi, debounce 3 giây, retry lùi dần từ 30 giây đến tối đa 5 phút; thiết lập lưu qua `SyncSettingsStore` (shared_preferences).
- Danh mục tài sản (`features/asset_catalog`) lưu `baseJson` / `conflictJson` trên `AssetModel` để đối chiếu 3 bên (`domain/asset_merge.dart`); xung đột hiện ở `/sync/conflicts`.

### Pipeline Edge AI (`features/edge_vision`, `core/ai_pipeline/ai_config.dart`)
- Mô hình `assets/models/object_detection.tflite`, input 1×3×640×640 (NCHW), output 1×13×8400 (cx, cy, w, h + điểm của 9 lớp; nhãn trong `labels.txt`).
- Chỉ ô vuông giữa khung hình (`AiConfig.cropFraction` = 70% cạnh ngắn, khớp khung xanh trên màn quét) được đưa vào mô hình. Ngưỡng tin cậy: 0.5 cho thiết bị, 0.7 cho nhóm hư hỏng (lớp 0, 1, 2, 5). Frame mới bị bỏ qua khi AI đang xử lý.
- iOS chạy bằng GPU delegate Metal, lỗi thì tự chuyển sang CPU.
- `mobile_scanner` là **bản vá cục bộ** trong `third_party/mobile_scanner` (khai báo qua `dependency_overrides` trong pubspec). Bản vá iOS/macOS vẫn gửi frame khi không có mã (~2 frame/giây) và gửi kèm khoá `aiInput` chứa ảnh RGB 640×640 đã cắt sẵn. Android **chưa vá** (AI chỉ chạy khi camera thấy mã). Đọc `third_party/mobile_scanner/PATCH_NOTES.md` trước khi sửa.

### Đánh giá hư hỏng bề mặt và chi phí (`features/damage_assessment`)
- Luồng: quét QR dán trên bề mặt (thẻ 10 cm, `AiConfig.markerSizeCm`) → `ScannerController._measure` chạy AI trên chính khung đó → `DamageMeasurer` quy khung phát hiện ra m²/mét theo cạnh thẻ QR → phiếu kiểm kê (`SurfaceAssessmentSection`) cho sửa số, nhập diện tích bề mặt → `DamageCalculator` tính chỉ số 0–100, mức độ, chi phí theo bảng đơn giá.
- `AiConfig.damageTypeByClass` ánh xạ lớp model sang `DamageType`; đổi khi thay model phân vùng 4 lớp.
- Bảng đơn giá `repair_cost_rates` (chỉ admin sửa) được `RepairRateRepository` tải và lưu offline; không có thì dùng `sampleRepairRates` (giá minh hoạ, phải trùng `supabase/seed/repair_cost_rates_sample.sql`, có test kiểm tra).
- Phiếu lưu `SurfaceAssessment` dạng JSON kèm đơn giá lúc kiểm kê (`AuditRecordModel.applyAssessment`), cùng `estimatedCost`, `damageIndex`.
- `RepairCostSummary` gom chi phí theo tòa nhà (`area`) / phòng (`location`), lấy phiếu mới nhất của mỗi mã; dùng chung cho Tổng quan, Báo cáo và PDF. Màn `/repair-rates` cho admin sửa đơn giá (`RepairRateWriter`).

### Quản lý state
Riverpod 3, dùng lẫn provider sinh tự động (`@riverpod` + `*.g.dart`) và `Provider`/`AsyncNotifier` viết tay. Test truyền fake qua override của `ProviderScope`/`ProviderContainer` (ví dụ `isarAuditRepositoryProvider`, `syncRepositoryProvider`, `authRepositoryProvider`); các fake dùng chung nằm trong `test/helpers/`.

### Supabase
Thay đổi schema đặt trong `supabase/migrations/` (đặt tên theo timestamp, chạy theo thứ tự tên file); dữ liệu mẫu ở `supabase/seed/`. RLS: chỉ người đã đăng nhập truy cập được dữ liệu; phiếu kiểm kê chỉ người tạo (`created_by`) được sửa.

## Quy trình Git

Nhánh: `main` ← `develop` ← `feature/sprint<S>-card<N>-tv<K>`; thay đổi vào `develop` qua Pull Request. Commit theo Conventional Commits, mô tả bằng tiếng Việt, ví dụ `feat(card26): ...`, `fix(ai): ...`. `HUONG_DAN_GIT_NHOM.md` yêu cầu `git add` từng file cụ thể, không dùng `git add .`.
