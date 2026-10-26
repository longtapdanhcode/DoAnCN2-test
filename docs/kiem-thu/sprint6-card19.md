# Kiểm thử thủ công – Sprint 6, Card 19

Ngày: 24/10/2026 · Nhánh: `feature/sprint6-card19-tv3`

## Môi trường

| Nền tảng | Thiết bị | Kết quả build |
|---|---|---|
| iOS | iPhone 17 Simulator (iOS 27) | Build và chạy được (debug) |
| Android | — | Bỏ qua trong đợt này (xem mục "Android") |
| macOS | Máy phát triển | Build được (debug) |

Supabase: project DoAnCN2 (bảng `audit_records`, bucket `signatures`).

## Luồng đã đi

1. Tổng quan → **Quét thiết bị** → hộp xin quyền camera → cho phép.
2. Camera (simulator không có camera) → **Nhập mã thủ công** `TS-DC-0142`.
3. Lập phiếu: loại thiết bị, tên tài sản, khu vực → **Tiếp tục ký xác nhận**.
4. Ký trên canvas → **Hoàn tất kiểm kê** → "Đã lưu phiếu kiểm kê trên thiết bị".
5. Phiếu → phiếu `KK-2026-001` hiện trong danh sách, "1 chờ" đồng bộ.
6. Đồng bộ dữ liệu → **Đồng bộ ngay** → "Đã đồng bộ 1 phiếu lên đám mây".
   Trên Supabase: bản ghi có đủ `area`, `condition`, `signer_name`, `signer_role`;
   `signature_url` mở được ảnh PNG.
7. Phiếu → **Xuất báo cáo PDF** → hộp chia sẻ iOS với `bao_cao_kiem_ke.pdf` (17 KB).

## Lỗi phát hiện và đã sửa

| # | Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|---|
| 1 | App crash (màn đỏ) khi bấm **Lập phiếu** trong hộp nhập mã thủ công | `TextEditingController` bị `dispose()` ngay sau `showDialog` trong khi ô nhập còn hiển thị lúc hộp thoại đóng | Tách `_ManualCodeDialog` tự giữ controller; thêm test `scanner_screen_test.dart` |
| 2 | Camera báo "The scanner was already started" sau hộp xin quyền | Sự kiện inactive/resumed sau hộp thoại làm `stop()` và `start()` chạy chồng nhau; widget `MobileScanner` cũng tự bật/tắt theo vòng đời | `useAppLifecycleState: false`; xếp hàng các lệnh camera trong `ScannerController` |
| 3 | Lỗi camera hiện thông điệp tiếng Anh, không có lối thoát, bị khung quét đè lên | Dùng thẳng thông điệp của plugin | Thông báo tiếng Việt, nút **Thử lại** và **Nhập mã thủ công**; ẩn khung quét khi lỗi |
| 4 | Chữ thanh trạng thái màu đen trên header tối (Tổng quan, Đồng bộ) | Không khai báo kiểu thanh trạng thái | `AnnotatedRegion` sáng cho header tối, tối cho phần còn lại |
| 5 | Bản mobile không có ô **Tên tài sản** nên phiếu đồng bộ lên có `asset_name = null` | Thiếu trường trên giao diện mobile | Thêm ô Tên tài sản; tiêu đề thẻ ưu tiên tên tài sản |
| 6 | Không đóng được bàn phím (Return không làm gì, chạm ra ngoài không đóng) | Thiếu `textInputAction` và xử lý chạm ra ngoài | Return chuyển sang ô kế tiếp; chạm ra ngoài hoặc cuộn để đóng |
| 7 | Dòng "AI On-Device · Xử lý ngay trên thiết bị" tràn ngang trên màn hẹp | Chữ không co giãn | Bọc `Flexible` + cắt chữ |

## Android

Theo yêu cầu, đợt này không build Android. Lần thử build `flutter build apk --debug`
trước khi dừng gặp hai lỗi cần xử lý khi làm lại (chưa sửa trong code):

1. `tflite_flutter`: Java biên dịch cho JVM 11 nhưng Kotlin cho JVM 17
   ("Inconsistent JVM Target Compatibility"). Hướng sửa: đặt `jvmTarget = 11` cho
   Kotlin của plugin này trong `android/build.gradle.kts`.
2. `permission_handler_android` yêu cầu `compileSdk` ≥ 37, app đang dùng 36
   (AGP 9.1.0 khuyến nghị tối đa 36). Hướng sửa: nâng `compileSdk` lên 37 hoặc
   nâng Android Gradle Plugin.

## Chưa kiểm được

- **Quét bằng camera thật**: simulator không có camera. Cần thử trên iPhone/Android thật
  (quét QR, mã vạch, bật đèn, đổi camera, và lỗi số 2 với camera thật).
- **Cài lên máy thật**: chưa cài lên iPhone/Android của nhóm.
- **Nội dung file PDF**: mới thấy hộp chia sẻ, chưa mở file xem từng cột.
- **Mất mạng thật**: chưa bật/tắt Wi-Fi trên thiết bị để xem trạng thái "Ngoại tuyến".

## Dữ liệu thử còn lại

Phiếu thử `TS-DC-0142` (id `1a845f36-98b7-4944-bf11-7c9e7af89e76`) và ảnh
`signatures/sig_1792853479282.png` đã được đồng bộ lên Supabase trong lúc kiểm thử.
