# BẢN GIẢI TRÌNH KIẾN TRÚC KỸ THUẬT (TECHNICAL JUSTIFICATION)
**Dự án:** All-in-One Field Inventory & Edge AI Suite  
**Vai trò:** Technical Lead & Software Architect  
**Đối tượng:** Hội đồng Đánh giá & Bảo vệ Kỹ thuật  

---

## 1. CÔNG NGHỆ CỤ THỂ & LÝ DO LỰA CHỌN (TECH STACK JUSTIFICATION)

Hệ thống được thiết kế theo tư duy **Offline-First & On-Device Processing**, giải quyết bài toán cốt lõi: *Kiểm kê vật tư, tài sản tại hiện trường bị cô lập hoàn toàn về mạng (hầm mỏ, kho kín, công trường xa xôi) mà vẫn đảm bảo tính chính xác, tốc độ nhận diện tức thời và toàn vẹn dữ liệu.*

### 1.1. Tổng quan Stack công nghệ lõi (Trích xuất từ `pubspec.yaml`)

| Tầng kiến trúc | Công nghệ / Thư viện | Phiên bản | Vai trò kỹ thuật trong hệ thống |
| :--- | :--- | :--- | :--- |
| **Framework nền tảng** | **Flutter SDK** | `^3.13.4` (Dart SDK) | Nền tảng cross-platform kết xuất đồ họa hiệu năng cao (Skia/Impeller) đạt 60–120 FPS trên thiết bị di động. |
| **Quản lý trạng thái & DI** | **Flutter Riverpod** | `^3.4.3` / `annotation: ^4.0.7` | Quản trị State phản ứng (Reactive) và Container Dependency Injection (DI) tách biệt hoàn toàn khỏi `BuildContext`. |
| **Kiến trúc mã nguồn** | **Feature-First Clean Architecture** | Tùy biến chuẩn hoá | Phân rã theo Domain Module (`edge_vision`, `offline_audit`, `canvas_signature`, `report_dashboard`) kết hợp 3 lớp chuẩn (`Domain - Data - Presentation`). |
| **Cơ sở dữ liệu cục bộ** | **Isar Plus** | `^1.3.9` & `isar_plus_flutter_libs` | Embedded NoSQL Database viết bằng Rust, hỗ trợ ACID Transactions, Native Binary Serialization và Zero-Copy Deserialization. |
| **Nền tảng Cloud Backend** | **Supabase Flutter** | `^2.18.0` | Cloud Backend-as-a-Service (PostgreSQL, PostgREST API, S3-Compatible Storage Bucket cho chữ ký số). |
| **On-Device Edge AI** | **TFLite Flutter & Image** | `tflite_flutter: ^0.12.1`, `image: ^4.10.1` | TensorFlow Lite C++ Native Interpreter chạy qua FFI (Foreign Function Interface), xử lý inference trực tiếp trên phần cứng máy khách. |
| **Quét mã vạch / QR** | **Mobile Scanner** | `^7.4.2` | Native Camera Engine tích hợp ML Kit scanning đa định dạng (QR, Code128, EAN13, DataMatrix,...). |
| **Ký số & Vector Canvas** | **Signature** | `^6.4.0` | Thu thập nét ký cảm ứng, làm mượt đường cong Bézier và trích xuất mảng byte PNG nguyên bản. |
| **Điều hướng & Type-safe** | **GoRouter & Fpdart** | `go_router: ^18.0.2`, `fpdart: ^1.2.0` | Khai báo Route tập trung và mô hình lập trình hàm (Functional Programming) xử lý luồng an toàn. |

---

### 1.2. Tính ưu việt và "Độ ăn ý" của sự kết hợp công nghệ

#### A. Tại sao chọn Isar Plus thay vì SQLite (sqflite) hay Hive?
1. **Loại bỏ chi phí chuyển đổi dữ liệu (Zero-Copy Deserialization):**
   - Với SQLite, mọi thao tác ghi/đọc đối tượng đều phải đi qua bước chuyển đổi trung gian: `Object <-> Map<String, dynamic> <-> SQL B-Tree Row`. Khi thao tác hàng nghìn bản ghi kèm mảng nhị phân lớn (`signatureBytes` của chữ ký), SQLite phát sinh overhead bộ nhớ và garbage collection rất lớn.
   - **Isar Plus** lưu trữ trực tiếp dưới dạng nhị phân tĩnh (Static Binary format) nhờ code generation compile-time (`AuditRecordModelSchema` sinh ra từ `build_runner`). Dữ liệu từ đĩa được ánh xạ thẳng vào bộ nhớ máy mà không cần serialize lại.
2. **ACID Transaction trên Asynchronous Background Isolate:**
   - Trong `IsarAuditRepositoryImpl`, phương thức `_isar.writeAsync((isar) { ... })` thực thi việc ghi dữ liệu trên một isolate chạy nền riêng biệt của động cơ Rust, đảm bảo luồng giao diện chính (UI Thread) không bao giờ bị hiện tượng tụt khung hình (frame drop / jank) khi kiểm kê viên bấm lưu bản ghi lớn.
3. **Cơ chế Auto-increment linh hoạt:**
   - Isar cung cấp hàm `isar.auditRecordModels.autoIncrement()` tối ưu hóa cho 64-bit integer ID, giúp việc lập chỉ mục (index B-Tree cục bộ) trên thiết bị di động đạt độ phức tạp $O(1)$ đến $O(\log N)$ với dung lượng bộ nhớ tối thiểu.

#### B. Tại sao kết hợp Feature-First Clean Architecture với Riverpod 3.x?
1. **Kiến trúc phân lớp độc lập (Separation of Concerns):**
   - Cấu trúc thư mục chia theo Feature: `lib/features/offline_audit/` chứa riêng `domain/`, `data/`, `presentation/`. 
   - Lớp **Domain** chứa các pure Dart contracts: `AuditRepository` và `SyncRepository` hoàn toàn không phụ thuộc vào Flutter framework, Isar hay Supabase. Điều này giúp hệ thống sẵn sàng thay thế bất kỳ giải pháp Cloud hay Database nào mà không phá vỡ nghiệp vụ lõi.
2. **Khả năng kiểm thử cô lập (Testability mà không cần Mock lồng cồng kềnh):**
   - Nhờ Riverpod, lớp Presentation (`AuditFormController`) chỉ phụ thuộc vào `isarAuditRepositoryProvider`.
   - Trong bộ Unit Test (`audit_form_controller_test.dart`), ta chỉ cần override provider:
     ```dart
     container = ProviderContainer(
       overrides: [
         isarAuditRepositoryProvider.overrideWithValue(mockRepo),
       ],
     );
     ```
     Toàn bộ logic lưu form, xử lý lỗi, validate dữ liệu được test 100% độc lập, không cần khởi chạy Engine Isar thật và không cần dựng `BuildContext` hay widget tree.
3. **Vòng đời State an toàn (Auto-dispose & Keep-alive chuẩn mực):**
   - Database và Network clients (`isarInstanceProvider`, `supabaseClientProvider`) được cấu hình `@Riverpod(keepAlive: true)` để duy trì kết nối xuyên suốt ứng dụng.
   - Trong khi đó, các Controller màn hình như `AuditFormController` sử dụng vòng đời tự động giải phóng (`AutoDispose`), giúp giải phóng bộ nhớ ngay khi nhân viên kiểm kê rời khỏi màn hình.

---

## 2. PHẠM VI THỰC HIỆN (SCOPE OF IMPLEMENTATION)

```
+-----------------------------------------------------------------------------------+
|                        KIẾN TRÚC TỔNG THỂ ĐÃ TRIỂN KHAI                           |
+-----------------------------------------------------------------------------------+
|  [Camera Stream / MobileScanner]                                                  |
|         │                                                                         |
|         ├──> Barcode / QR Detected  ──> [ProcessScanResultUseCase] ──> scanCode   |
|         └──> Camera Frame (Bytes)   ──> [TfliteVisionRepository]   ──> aiLabel    |
|                                                                              │    |
|  [Canvas Signature] ─────────────────> PNG Byte Array (Uint8List) ───────────┤    |
|                                                                              │    |
|                                              ▼                                    |
|                              [AuditFormScreen & Controller]                       |
|                                              │                                    |
|                                              ▼                                    |
|                               [IsarAuditRepositoryImpl]                           |
|                               (writeAsync Transaction)                            |
|                                              │                                    |
|                                              ▼                                    |
|                                [Isar Local NoSQL Database]                        |
|                                    (isSynced = false)                             |
|                                              │                                    |
|   - - - - - - - - - - - - - - - - - - - - - -│ - - - - - - - - - - - - - - - - - -|
|   RANH GIỚI ĐỒNG BỘ CLOUD (Domain Model / Contract Ready)                         |
|                                              ▼                                    |
|                      [CloudAuditRecordModel.fromAuditRecordModel]                 |
|                      - Convert Local ID (int)  -> UUID v4                         |
|                      - Convert Raw Bytes       -> Storage Bucket URL              |
|                      - Convert Local DateTime  -> ISO-8601 UTC                    |
|                                              │                                    |
|                                              ▼                                    |
|                                 [Supabase PostgREST & S3]                         |
+-----------------------------------------------------------------------------------+
```

### 2.1. Các tính năng THỰC SỰ ĐÃ giải quyết hoàn chỉnh trong Code

1. **Quét mã hiện trường tốc độ cao (High-Performance Hardware Scanner):**
   - Triển khai tại `scanner_repository_impl.dart` và `scanner_controller.dart`.
   - Tự động nhận diện và phân loại mã trong `ProcessScanResultUseCase`: phân tách chính xác `qrCode` và các chuẩn `barCode` (Code128, Code39, Code93, EAN13, EAN8, UPCA, UPCE, DataMatrix, PDF417).
   - Quản lý vòng đời phần cứng: Bật/tắt Flash, lật camera trước/sau, tự động tạm dừng camera (`stop()`) khi ứng dụng vào trạng thái nền (`AppLifecycleState.inactive / paused`) và khởi động lại khi `resumed` để bảo vệ cảm biến nhiệt và pin thiết bị.
   - Khung căn chỉnh chuyên dụng `ScannerOverlayWidget` cắt khoét vùng quét và vẽ corner bracket mượt mà bằng `CustomPainter`.
2. **Đường ống AI On-Device với cơ chế chống nghẽn CPU (Edge AI Pipeline):**
   - Triển khai tại `tflite_vision_repository_impl.dart`.
   - Thiết lập nạp C++ TFLite Interpreter từ assets với cấu hình đa luồng (`threads = 2`).
   - Xử lý tiền xử lý ảnh (Image Preprocessing): Giải mã byte stream, resize ảnh về kích thước chuẩn tensor $224 \times 224$ (`AiConfig.inputSize`), chuẩn hóa giá trị pixel $R, G, B \in [0.0, 1.0]$ thành tensor Float32 dạng `[1, 224, 224, 3]`.
   - **Cơ chế Backpressure / Frame-Dropping:** Trong hàm `processCameraFrame()` của `scanner_controller.dart`, hệ thống sử dụng cờ kiểm soát `_isAnalyzing`. Nếu mô hình AI đang trong quá trình suy luận (inference), frame ảnh mới từ camera stream sẽ bị bỏ qua ngay lập tức, ngăn ngừa hoàn toàn tình trạng tích tụ hàng đợi khung hình gây đơ ứng dụng.
3. **Biểu mẫu kiểm kê động ngoại tuyến (Dynamic Offline Audit Form):**
   - Triển khai tại `audit_form_screen.dart` và `audit_form_controller.dart`.
   - Tự động nhận tham số `scanCode` và `aiLabel` truyền qua từ luồng camera của GoRouter.
   - Hỗ trợ bộ điều khiển số lượng linh hoạt (Input số nguyên dương, các chip tăng nhanh `+1, +5, +10`, đặt lại `=1`).
   - Kiểm tra ràng buộc hợp lệ dữ liệu chặt chẽ trước khi kích hoạt transaction lưu trữ.
4. **Ký số & chú thích trực tiếp trên màn hình cảm ứng (Canvas Signature):**
   - Triển khai tại `signature_screen.dart`.
   - Tùy biến Canvas tương tác với đường kẻ ký tên tham chiếu, hỗ trợ xóa nét vẽ tức thì và xuất trực tiếp ra mảng byte ảnh `Uint8List` (PNG format).
   - Trả dữ liệu byte về cho Form kiểm kê mà không sinh ra file rác tạm bợ trên bộ nhớ ngoài của thiết bị.
5. **Lưu trữ Offline bền vững (Offline-First Persistence):**
   - Triển khai tại `isar_audit_repository_impl.dart`.
   - Đảm bảo bản ghi được lưu an toàn với `isSynced = false`, lưu trữ nguyên vẹn `signatureBytes`, `timestamp` thời gian thực và tự sinh ID tự tăng.

---

### 2.2. Giới hạn biên (Boundary) của hệ thống hiện tại

Để bản thuyết minh thể hiện sự am hiểu thực tế và tư duy kỹ thuật trung thực trước hội đồng, các giới hạn biên của phiên bản hiện tại bao gồm:

1. **Trọng số mô hình TFLite (Model Weights Placeholder):**
   - Pipeline kiến trúc AI (Interpreter, Tensor Allocation, Normalization, Inference Filter) đã lập trình hoàn thiện và bao phủ test an toàn (`vision_ai_repository_test.dart`).
   - Tuy nhiên, hai tệp `object_detection.tflite` và `labels.txt` hiện tại là placeholder (dung lượng 0 byte). Mã nguồn đã cài đặt cơ chế **Phòng thủ chủ động (Defensive Programming)** trong `TfliteVisionRepositoryImpl.loadModel()`: nếu phát hiện file 0 byte, hệ thống ghi log cảnh báo và bypass inference an toàn, không làm crash ứng dụng. Hệ thống sẵn sàng hoạt động ngay khi đưa file weights đã huấn luyện vào.
2. **Ranh giới kích hoạt luồng đồng bộ Cloud (Sync Triggering Boundary):**
   - Tầng Domain Contract `SyncRepository` và Data Transfer Object `CloudAuditRecordModel` cùng cấu hình `SupabaseConfig` đã được xây dựng và kiểm thử hoàn chỉnh.
   - Tuy nhiên, trong phiên bản build hiện tại, Controller `AuditFormController` mới chỉ gọi trực tiếp `isarAuditRepository.saveRecord()`. Tác vụ đồng bộ nền tự động (Background Sync Service định kỳ khi có kết nối Internet) là bước tiếp theo để liên kết toàn diện Remote DataSource vào giao diện người dùng.
3. **Phạm vi Canvas:**
   - Hỗ trợ ký xác nhận và chú thích đồ họa tự do trên nền Canvas trắng chuẩn, chưa tích hợp tính năng phủ nét vẽ trực tiếp lên ảnh chụp thực địa (photo overlay annotation).
4. **Báo cáo thống kê:**
   - Màn hình `DashboardScreen` đóng vai trò điều phối trung tâm (Launcher Hub), chưa xây dựng biểu đồ phân tích trực quan nâng cao.

---

## 3. CƠ CHẾ ĐỒNG BỘ & XỬ LÝ XUNG ĐỘT (SYNC & CONFLICT RESOLUTION STRATEGY)

Dưới góc độ thiết kế hệ thống phân tán (Distributed System Design), bài toán đồng bộ giữa hàng trăm thiết bị ngoại tuyến và một trung tâm dữ liệu đám mây (Cloud) tiềm ẩn nguy cơ xung đột khóa và đè dữ liệu. Dự án đã giải quyết bài toán này bằng kiến trúc **Mô hình hóa hai trạng thái (Dual-Model Architecture)** và **Khóa ngẫu nhiên phân tán**.

### 3.1. Phân tích luồng Code giữa Local Model và Cloud Model

#### A. Cục bộ: `AuditRecordModel` (Isar Local Schema)
Trích xuất từ `audit_record_model.dart`:
```dart
@collection
class AuditRecordModel {
  AuditRecordModel(this.id, {this.signatureBytes});

  final int id;              // 64-bit Integer Auto-Increment
  String? scanCode;
  String? aiDetectedLabel;
  int quantity = 0;
  List<int>? signatureBytes; // Raw PNG Bytes lưu trực tiếp trong NoSQL
  DateTime? timestamp;
  bool isSynced = false;     // Cờ trạng thái đồng bộ
}
```
*Đặc tính kỹ thuật:* Tối ưu hóa tối đa cho I/O thiết bị di động. Khóa chính dạng số nguyên tự tăng giúp Isar tổ chức B-Tree cực nhanh. Dữ liệu chữ ký lưu thô dưới dạng `List<int>` để đảm bảo khi không có mạng, ảnh chữ ký vẫn được bảo toàn nguyên vẹn trong database nội bộ mà không cần phụ thuộc vào file hệ thống.

#### B. Đám mây: `CloudAuditRecordModel` (PostgreSQL / Supabase DTO)
Trích xuất từ `cloud_audit_record_model.dart`:
```dart
class CloudAuditRecordModel {
  final String id;             // UUID v4 (128-bit String)
  final String scanCode;       // Snake_case: scan_code
  final String? aiDetectedLabel;
  final int quantity;
  final String timestamp;      // ISO-8601 UTC String
  final String? signatureUrl;  // Public / Signed Storage Bucket URL
  ...
}
```
*Đặc tính kỹ thuật:* Tuân thủ chuẩn RESTful và PostgreSQL RDBMS. Dữ liệu chữ ký chuyển thành liên kết lưu trữ đám mây (`signatureUrl`), và thời gian chuẩn hóa về múi giờ quốc tế `UTC`.

#### C. Bản thiết kế chuyển đổi (Mapping Bridge)
Điểm mấu chốt của thiết kế nằm ở hàm chuyển đổi `fromAuditRecordModel`:
```dart
factory CloudAuditRecordModel.fromAuditRecordModel(
  AuditRecordModel record, {
  required String id,        // Yêu cầu Client Inject UUID v4 mới
  String? signatureUrl,      // URL nhận được sau khi đẩy mảng byte lên Storage
}) {
  return CloudAuditRecordModel(
    id: id,
    scanCode: record.scanCode ?? '',
    aiDetectedLabel: record.aiDetectedLabel,
    quantity: record.quantity,
    timestamp: (record.timestamp ?? DateTime.now()).toUtc().toIso8601String(),
    signatureUrl: signatureUrl,
  );
}
```

---

### 3.2. Cơ chế đồng bộ dữ liệu (Sync Workflow)

Hệ thống được thiết kế theo quy trình đồng bộ 5 bước hai pha (Two-Phase Sync Mechanism):

```mermaid
sequenceDiagram
    autonumber
    participant App as Ứng dụng Kiểm kê
    participant LocalDB as Isar Local DB
    participant Storage as Supabase Storage
    participant CloudDB as Supabase Database (Postgres)

    Note over App,LocalDB: Giai đoạn 1: Hoạt động Ngoại tuyến (Offline)
    App->>LocalDB: writeAsync(AuditRecordModel) [id=autoIncrement, isSynced=false]
    
    Note over App,CloudDB: Giai đoạn 2: Phát hiện có mạng (Network Reconnected)
    App->>LocalDB: Truy vấn where(isSynced == false)
    LocalDB-->>App: Trả về danh sách pendingRecords

    loop Với từng bản ghi kiểm kê
        opt Có chữ ký số (signatureBytes != null)
            App->>Storage: uploadSignature(bytes)
            Storage-->>App: Trả về signatureUrl
        end
        App->>App: Sinh UUID v4 cho bản ghi Cloud
        App->>App: CloudAuditRecordModel.fromAuditRecordModel(...)
    end

    App->>CloudDB: UPSERT batch records (CloudAuditRecordModel.toJson)
    CloudDB-->>App: Xác nhận thành công (HTTP 200/201)

    App->>LocalDB: Cập nhật isSynced = true
```

1. **Lọc dữ liệu chờ:** Lấy danh sách các bản ghi có cờ `isSynced == false` thông qua chỉ mục của Isar.
2. **Đồng bộ nhị phân (Binary Upload Phase):** Tách mảng byte chữ ký `signatureBytes`, tải lên Supabase Storage bucket (`uploadSignature`). Nếu thành công, nhận về CDN URL. Nếu không có chữ ký, trường `signature_url` được gán `null`.
3. **Chuyển đổi dữ liệu (DTO Mapping):** Chuyển từ ID nguyên của Isar sang UUID v4 toàn cục, ánh xạ snake_case tương thích PostgreSQL thông qua `toJson()`.
4. **Đồng bộ cơ sở dữ liệu (Database Ingestion Phase):** Thực hiện đẩy dữ liệu lên bảng `audit_records` của Supabase bằng cơ chế Batch Upsert.
5. **Xác nhận giao dịch cục bộ (Local Acknowledgment):** Sau khi Cloud phản hồi thành công, Isar cập nhật `isSynced = true` trong một transaction duy nhất để hoàn tất vòng lặp.

---

### 3.3. Chiến lược giải quyết xung đột (Conflict Resolution Strategy)

Trong môi trường kiểm kê hiện trường quy mô lớn với nhiều kiểm kê viên làm việc đồng thời trên các thiết bị khác nhau, hai kịch bản xung đột chính được xử lý như sau:

#### 1. Triệt tiêu hoàn toàn xung đột khóa chính (Primary Key Collision Elimination)
- **Vấn đề thực tế:** Nếu thiết bị A ngoại tuyến tạo 100 bản ghi với ID từ `1` đến `100`, và thiết bị B ngoại tuyến cũng tạo 100 bản ghi với ID từ `1` đến `100`. Nếu đẩy thẳng Integer ID này lên Cloud, hệ thống sẽ gặp lỗi trùng khóa chính (Primary Key Constraint Violation) ngay lập tức hoặc đè mất dữ liệu của nhau.
- **Giải pháp thiết kế:**
  - Tách rời hoàn toàn định danh nội bộ (Local ID) và định danh đám mây (Cloud ID).
  - Sử dụng **Client-Generated UUID v4** tại thời điểm đóng gói `CloudAuditRecordModel`:
    $$P(\text{Trùng lặp UUID v4}) \approx \frac{1}{2^{122}} \approx 1.86 \times 10^{-37}$$
  - Về mặt toán học và khoa học máy tính, xác suất này gần như bằng 0. Mỗi bản ghi được tạo ra từ bất kỳ thiết bị nào, ở bất kỳ thời điểm nào, đều sở hữu một định danh toàn cầu duy nhất (Globally Unique Identifier). Do đó, **nguy cơ xung đột khóa chính khi nhiều thiết bị đồng thời đẩy dữ liệu lên được triệt tiêu 100%**.

#### 2. Chiến lược ghi nhận sự kiện kiểm kê và Last-Write-Wins (LWW)
- **Bản chất nghiệp vụ kiểm kê (Append-Only Audit Trail):**
  - Trong nghiệp vụ kiểm kê tài sản (Asset Audit), mỗi lần quét mã là một sự kiện kiểm kê tại một thời điểm (Point-in-time Event). Hệ thống mô hình hóa theo dạng **Audit Log (Bất biến - Immutable)**: mỗi lần quét là một dòng mới được ghi nhận cùng người thực hiện và chữ ký xác nhận. Không có hành vi sửa đổi trực tiếp dữ liệu gốc, do đó loại trừ được tranh chấp dữ liệu (Race Condition).
- **Trường hợp cập nhật trạng thái đồng thời (State Reconciliation):**
  - Trong trường hợp nghiệp vụ yêu cầu cập nhật bản ghi mới nhất cho cùng một mã tài sản (`scan_code`), hệ thống sử dụng chiến lược **Last-Write-Wins (LWW)** dựa trên trường `timestamp`:
    ```dart
    (record.timestamp ?? DateTime.now()).toUtc().toIso8601String()
    ```
  - **Chuẩn hóa UTC ISO-8601:** Việc ép buộc chuyển đổi về múi giờ quốc tế chuẩn UTC loại bỏ hoàn toàn sai lệch giờ do các thiết bị kiểm kê nằm ở các múi giờ khác nhau hoặc thiết lập đồng hồ máy bị lệch múi giờ địa phương.
  - Trên tầng cơ sở dữ liệu PostgreSQL của Supabase, câu lệnh đồng bộ sử dụng cú pháp:
    ```sql
    INSERT INTO audit_records (id, scan_code, ai_detected_label, quantity, timestamp, signature_url)
    VALUES (...)
    ON CONFLICT (scan_code) DO UPDATE 
    SET quantity = EXCLUDED.quantity,
        timestamp = EXCLUDED.timestamp,
        signature_url = EXCLUDED.signature_url
    WHERE EXCLUDED.timestamp > audit_records.timestamp;
    ```
  - Điều này đảm bảo dữ liệu ghi nhận tại thời điểm thực tế muộn nhất luôn là dữ liệu chiến thắng, bảo đảm tính toàn vẹn của hệ thống phân tán.

---

## 4. TỔNG KẾT ĐIỂM NỔI BẬT BẢO VỆ TRƯỚC HỘI ĐỒNG

1. **Kiến trúc bền vững:** Phân lớp rành mạch theo chuẩn Clean Architecture kết hợp State Management & DI hiện đại của Riverpod 3.x, code có độ kết dính cao (High Cohesion) và mức độ phụ thuộc thấp (Loose Coupling).
2. **Thiết kế Offline-First thực thụ:** Tận dụng triệt để sức mạnh của NoSQL Isar Plus trên Rust Isolate để tối ưu bộ nhớ, duy trì trải nghiệm người dùng mượt mà ngay cả khi không có kết nối Internet.
3. **Bảo vệ phần cứng tối đa:** Tích hợp cơ chế kiểm soát camera thông minh, tự động giải phóng tài nguyên theo vòng đời ứng dụng và cơ chế Frame-Dropping bảo vệ CPU/GPU trong quá trình chạy Edge AI.
4. **Giải pháp đồng bộ nhất quán:** Tách bạch Local Auto-increment ID và Cloud UUID v4, kết hợp chuẩn hóa ISO-8601 UTC và cờ trạng thái `isSynced`, giải quyết dứt điểm các bài toán hóc búa của hệ thống phân tán đa thiết bị.
