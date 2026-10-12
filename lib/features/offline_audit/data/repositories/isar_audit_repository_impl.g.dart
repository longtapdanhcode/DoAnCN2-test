// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_audit_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider cung cấp instance [AuditRepository] với tên [isarAuditRepositoryProvider].
///
/// Phụ thuộc vào [isarInstanceProvider] đã được khởi tạo trong `core/database/local_db_init.dart`.

@ProviderFor(isarAuditRepository)
final isarAuditRepositoryProvider = IsarAuditRepositoryProvider._();

/// Riverpod provider cung cấp instance [AuditRepository] với tên [isarAuditRepositoryProvider].
///
/// Phụ thuộc vào [isarInstanceProvider] đã được khởi tạo trong `core/database/local_db_init.dart`.

final class IsarAuditRepositoryProvider
    extends
        $FunctionalProvider<AuditRepository, AuditRepository, AuditRepository>
    with $Provider<AuditRepository> {
  /// Riverpod provider cung cấp instance [AuditRepository] với tên [isarAuditRepositoryProvider].
  ///
  /// Phụ thuộc vào [isarInstanceProvider] đã được khởi tạo trong `core/database/local_db_init.dart`.
  IsarAuditRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isarAuditRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isarAuditRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuditRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditRepository create(Ref ref) {
    return isarAuditRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditRepository>(value),
    );
  }
}

String _$isarAuditRepositoryHash() =>
    r'72391e7e7e309364f884bd7556aedc2e4bd8ad55';

/// Riverpod provider cung cấp instance [AuditRepository] (alias tương thích).

@ProviderFor(auditRepository)
final auditRepositoryProvider = AuditRepositoryProvider._();

/// Riverpod provider cung cấp instance [AuditRepository] (alias tương thích).

final class AuditRepositoryProvider
    extends
        $FunctionalProvider<AuditRepository, AuditRepository, AuditRepository>
    with $Provider<AuditRepository> {
  /// Riverpod provider cung cấp instance [AuditRepository] (alias tương thích).
  AuditRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuditRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditRepository create(Ref ref) {
    return auditRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditRepository>(value),
    );
  }
}

String _$auditRepositoryHash() => r'60807e53a2ed965d84638fc4079893bb3e4d0802';
