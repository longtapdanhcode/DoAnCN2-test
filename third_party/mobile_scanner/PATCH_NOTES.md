# Bản vá mobile_scanner 7.4.2

Bản sao cục bộ của `mobile_scanner` 7.4.2 (BSD-3, xem LICENSE) dùng qua `dependency_overrides`.

**Thay đổi 1** (iOS/macOS, `darwin/.../MobileScannerPlugin.swift`): plugin gốc bỏ qua khung hình
không có mã (`if results.isEmpty { return }`), nên Edge AI chỉ chạy khi camera thấy QR. Bản vá vẫn gửi
khung hình với `barcodes` rỗng (tối đa ~2 khung/giây) khi `returnImage = true`.

Android **chưa vá** (AI trên Android sẽ chỉ chạy khi thấy mã cho tới khi vá tương tự ở Kotlin).

**Thay đổi 2** (iOS/macOS): khi `returnImage = true`, sự kiện gửi kèm khóa `aiInput`. Đây là ảnh
RGB 640×640 lấy từ ô vuông giữa khung hình (cạnh = 70% cạnh ngắn, khớp `AiConfig.cropFraction`),
cắt và thu nhỏ bằng CoreGraphics. Edge AI đọc khóa này qua `BarcodeCapture.raw`, không phải giải
mã JPEG trong Dart.
