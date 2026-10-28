// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_sync_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider cung cấp instance [SyncRepository].

@ProviderFor(syncRepository)
final syncRepositoryProvider = SyncRepositoryProvider._();

/// Riverpod provider cung cấp instance [SyncRepository].

final class SyncRepositoryProvider
    extends $FunctionalProvider<SyncRepository, SyncRepository, SyncRepository>
    with $Provider<SyncRepository> {
  /// Riverpod provider cung cấp instance [SyncRepository].
  SyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRepositoryHash();

  @$internal
  @override
  $ProviderElement<SyncRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRepository create(Ref ref) {
    return syncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRepository>(value),
    );
  }
}

String _$syncRepositoryHash() => r'bbfad0ed48ea0c3238dc5a5fb0cc00e327a61dcd';
