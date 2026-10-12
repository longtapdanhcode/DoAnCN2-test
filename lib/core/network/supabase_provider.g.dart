// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider cung cấp instance [SupabaseClient] toàn cục cho toàn bộ ứng dụng.
///
/// Được khai báo `keepAlive: true` để giữ kết nối và trạng thái Auth xuyên suốt.
/// Trong môi trường kiểm thử, có thể dễ dàng override bằng MockSupabaseClient:
/// ```dart
/// container = ProviderContainer(
///   overrides: [
///     supabaseClientProvider.overrideWithValue(mockClient),
///   ],
/// );
/// ```

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

/// Provider cung cấp instance [SupabaseClient] toàn cục cho toàn bộ ứng dụng.
///
/// Được khai báo `keepAlive: true` để giữ kết nối và trạng thái Auth xuyên suốt.
/// Trong môi trường kiểm thử, có thể dễ dàng override bằng MockSupabaseClient:
/// ```dart
/// container = ProviderContainer(
///   overrides: [
///     supabaseClientProvider.overrideWithValue(mockClient),
///   ],
/// );
/// ```

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// Provider cung cấp instance [SupabaseClient] toàn cục cho toàn bộ ứng dụng.
  ///
  /// Được khai báo `keepAlive: true` để giữ kết nối và trạng thái Auth xuyên suốt.
  /// Trong môi trường kiểm thử, có thể dễ dàng override bằng MockSupabaseClient:
  /// ```dart
  /// container = ProviderContainer(
  ///   overrides: [
  ///     supabaseClientProvider.overrideWithValue(mockClient),
  ///   ],
  /// );
  /// ```
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'2df5a38617329a3bb0a7e149189bea875722d7b8';
