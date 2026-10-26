# Bản vá mobile_scanner 7.4.2

Bản sao cục bộ của `mobile_scanner` 7.4.2 (BSD-3, xem LICENSE) dùng qua `dependency_overrides`.

**Thay đổi duy nhất** (iOS/macOS, `darwin/.../MobileScannerPlugin.swift`): plugin gốc bỏ qua khung hình
không có mã (`if results.isEmpty { return }`), nên Edge AI chỉ chạy khi camera thấy QR. Bản vá vẫn gửi
khung hình với `barcodes` rỗng (tối đa ~2 khung/giây) khi `returnImage = true`.

Android **chưa vá** (AI trên Android sẽ chỉ chạy khi thấy mã cho tới khi vá tương tự ở Kotlin).
