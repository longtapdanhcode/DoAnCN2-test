// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scannerRepository)
final scannerRepositoryProvider = ScannerRepositoryProvider._();

final class ScannerRepositoryProvider
    extends
        $FunctionalProvider<
          ScannerRepository,
          ScannerRepository,
          ScannerRepository
        >
    with $Provider<ScannerRepository> {
  ScannerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannerRepositoryHash();

  @$internal
  @override
  $ProviderElement<ScannerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScannerRepository create(Ref ref) {
    return scannerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScannerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScannerRepository>(value),
    );
  }
}

String _$scannerRepositoryHash() => r'e898f82e8d703e2e90dcc3850e5c66ec3268b1b2';

@ProviderFor(processScanResultUseCase)
final processScanResultUseCaseProvider = ProcessScanResultUseCaseProvider._();

final class ProcessScanResultUseCaseProvider
    extends
        $FunctionalProvider<
          ProcessScanResultUseCase,
          ProcessScanResultUseCase,
          ProcessScanResultUseCase
        >
    with $Provider<ProcessScanResultUseCase> {
  ProcessScanResultUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'processScanResultUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$processScanResultUseCaseHash();

  @$internal
  @override
  $ProviderElement<ProcessScanResultUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProcessScanResultUseCase create(Ref ref) {
    return processScanResultUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProcessScanResultUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProcessScanResultUseCase>(value),
    );
  }
}

String _$processScanResultUseCaseHash() =>
    r'12a4e64a0d73f0f2f2e3eafd30dd913caf109a72';

@ProviderFor(ScannerController)
final scannerControllerProvider = ScannerControllerProvider._();

final class ScannerControllerProvider
    extends $NotifierProvider<ScannerController, ScannerUiState> {
  ScannerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannerControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannerControllerHash();

  @$internal
  @override
  ScannerController create() => ScannerController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScannerUiState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScannerUiState>(value),
    );
  }
}

String _$scannerControllerHash() => r'c325c0dc66ae947cdb992874662709afae68c844';

abstract class _$ScannerController extends $Notifier<ScannerUiState> {
  ScannerUiState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScannerUiState, ScannerUiState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ScannerUiState, ScannerUiState>,
              ScannerUiState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
