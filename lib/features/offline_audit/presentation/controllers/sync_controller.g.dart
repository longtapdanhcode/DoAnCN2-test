// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
final class SyncControllerProvider
    extends $AsyncNotifierProvider<SyncController, void> {
  /// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.
  SyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();
}

String _$syncControllerHash() => r'dd3e85d7ccd6a8d2560c04500cf9ba0ae968e580';

/// Controller quản lý luồng đồng bộ bản ghi kiểm kê ngoại tuyến lên Cloud Supabase.

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
