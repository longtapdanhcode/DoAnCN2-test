// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
///
/// Giữ sống suốt vòng đời app: đồng bộ có thể được gọi từ màn không theo dõi
/// provider này (ví dụ màn Tài sản), và một provider tự huỷ sẽ bị dọn ngay
/// giữa chừng, gây lỗi "Cannot use the Ref ... after it has been disposed".

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
///
/// Giữ sống suốt vòng đời app: đồng bộ có thể được gọi từ màn không theo dõi
/// provider này (ví dụ màn Tài sản), và một provider tự huỷ sẽ bị dọn ngay
/// giữa chừng, gây lỗi "Cannot use the Ref ... after it has been disposed".
final class SyncControllerProvider
    extends $AsyncNotifierProvider<SyncController, void> {
  /// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
  ///
  /// Giữ sống suốt vòng đời app: đồng bộ có thể được gọi từ màn không theo dõi
  /// provider này (ví dụ màn Tài sản), và một provider tự huỷ sẽ bị dọn ngay
  /// giữa chừng, gây lỗi "Cannot use the Ref ... after it has been disposed".
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();
}

String _$syncControllerHash() => r'8fd545f3491273668411aa0d48aa5872b23a790c';

/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
///
/// Giữ sống suốt vòng đời app: đồng bộ có thể được gọi từ màn không theo dõi
/// provider này (ví dụ màn Tài sản), và một provider tự huỷ sẽ bị dọn ngay
/// giữa chừng, gây lỗi "Cannot use the Ref ... after it has been disposed".

abstract class _$SyncController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
