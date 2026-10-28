// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_form_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller quản lý luồng nhập và lưu bản ghi kiểm kê hiện trường.
///
/// Sử dụng Riverpod [AutoDisposeNotifier] để tự động giải phóng tài nguyên
/// khi thoát khỏi màn hình kiểm kê.

@ProviderFor(AuditFormController)
final auditFormControllerProvider = AuditFormControllerProvider._();

/// Controller quản lý luồng nhập và lưu bản ghi kiểm kê hiện trường.
///
/// Sử dụng Riverpod [AutoDisposeNotifier] để tự động giải phóng tài nguyên
/// khi thoát khỏi màn hình kiểm kê.
final class AuditFormControllerProvider
    extends $NotifierProvider<AuditFormController, AuditFormState> {
  /// Controller quản lý luồng nhập và lưu bản ghi kiểm kê hiện trường.
  ///
  /// Sử dụng Riverpod [AutoDisposeNotifier] để tự động giải phóng tài nguyên
  /// khi thoát khỏi màn hình kiểm kê.
  AuditFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditFormControllerHash();

  @$internal
  @override
  AuditFormController create() => AuditFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditFormState>(value),
    );
  }
}

String _$auditFormControllerHash() =>
    r'92ab5b90228c935c3f6387d213960309d745501a';

/// Controller quản lý luồng nhập và lưu bản ghi kiểm kê hiện trường.
///
/// Sử dụng Riverpod [AutoDisposeNotifier] để tự động giải phóng tài nguyên
/// khi thoát khỏi màn hình kiểm kê.

abstract class _$AuditFormController extends $Notifier<AuditFormState> {
  AuditFormState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuditFormState, AuditFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuditFormState, AuditFormState>,
              AuditFormState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
