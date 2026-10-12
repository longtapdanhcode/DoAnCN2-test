// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db_init.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider toàn cục giữ instance Isar suốt vòng đời ứng dụng.
///
/// Provider này được khai báo `keepAlive: true` để đảm bảo Isar instance
/// không bao giờ bị dispose trong quá trình app chạy.
///
/// **Lưu ý**: Provider này cần được override trong `ProviderScope` ở `main.dart`
/// bằng instance thật từ `initIsar()`:
/// ```dart
/// ProviderScope(
///   overrides: [isarInstanceProvider.overrideWithValue(isar)],
///   child: MyApp(),
/// )
/// ```

@ProviderFor(isarInstance)
final isarInstanceProvider = IsarInstanceProvider._();

/// Riverpod provider toàn cục giữ instance Isar suốt vòng đời ứng dụng.
///
/// Provider này được khai báo `keepAlive: true` để đảm bảo Isar instance
/// không bao giờ bị dispose trong quá trình app chạy.
///
/// **Lưu ý**: Provider này cần được override trong `ProviderScope` ở `main.dart`
/// bằng instance thật từ `initIsar()`:
/// ```dart
/// ProviderScope(
///   overrides: [isarInstanceProvider.overrideWithValue(isar)],
///   child: MyApp(),
/// )
/// ```

final class IsarInstanceProvider extends $FunctionalProvider<Isar, Isar, Isar>
    with $Provider<Isar> {
  /// Riverpod provider toàn cục giữ instance Isar suốt vòng đời ứng dụng.
  ///
  /// Provider này được khai báo `keepAlive: true` để đảm bảo Isar instance
  /// không bao giờ bị dispose trong quá trình app chạy.
  ///
  /// **Lưu ý**: Provider này cần được override trong `ProviderScope` ở `main.dart`
  /// bằng instance thật từ `initIsar()`:
  /// ```dart
  /// ProviderScope(
  ///   overrides: [isarInstanceProvider.overrideWithValue(isar)],
  ///   child: MyApp(),
  /// )
  /// ```
  IsarInstanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isarInstanceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isarInstanceHash();

  @$internal
  @override
  $ProviderElement<Isar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Isar create(Ref ref) {
    return isarInstance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Isar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Isar>(value),
    );
  }
}

String _$isarInstanceHash() => r'8e6972b7f22333b41660600c915636078dd95ebd';
