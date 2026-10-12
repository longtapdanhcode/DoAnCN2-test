// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tflite_vision_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(visionAiRepository)
final visionAiRepositoryProvider = VisionAiRepositoryProvider._();

final class VisionAiRepositoryProvider
    extends
        $FunctionalProvider<
          VisionAiRepository,
          VisionAiRepository,
          VisionAiRepository
        >
    with $Provider<VisionAiRepository> {
  VisionAiRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visionAiRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visionAiRepositoryHash();

  @$internal
  @override
  $ProviderElement<VisionAiRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VisionAiRepository create(Ref ref) {
    return visionAiRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisionAiRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisionAiRepository>(value),
    );
  }
}

String _$visionAiRepositoryHash() =>
    r'13bd4187f1b6d55c2b0814c7202901675302411e';
