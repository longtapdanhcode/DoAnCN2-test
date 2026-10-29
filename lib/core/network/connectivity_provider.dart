import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` khi thiết bị có ít nhất một kết nối mạng (Wi-Fi, di động, Ethernet...).
///
/// Chỉ phản ánh trạng thái giao diện mạng của hệ điều hành, không đảm bảo
/// máy chủ Supabase truy cập được. Phát giá trị ban đầu rồi cập nhật mỗi khi
/// kết nối thay đổi.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
});

bool _hasNetwork(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

/// `true` khi thiết bị đang dùng Wi-Fi hoặc Ethernet (mạng không tính dung
/// lượng), dùng cho tuỳ chọn "Chỉ tải ảnh qua Wi-Fi".
final isOnWifiProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _hasWifi(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasWifi);
});

bool _hasWifi(List<ConnectivityResult> results) => results.any(
  (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
);

/// Trạng thái mạng hiện tại, dùng trước khi gọi máy chủ.
///
/// Giá trị chỉ có khi [isOnlineProvider] đang được theo dõi: khung app
/// (FieldlineShell) luôn theo dõi nó. Chưa biết trạng thái thì coi như có mạng
/// và để lệnh gọi máy chủ tự báo lỗi.
bool checkOnline(WidgetRef ref) => ref.read(isOnlineProvider).value ?? true;
