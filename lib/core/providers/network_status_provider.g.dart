// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentNetworkStatusHash() =>
    r'9cc373abb97535afc4ec7783bb7dc3b68eabbc7a';

/// A simple provider that returns the current network status as a boolean.
///
/// Returns `true` if online, and `false` if offline or in a loading/error state.
///
/// Copied from [currentNetworkStatus].
@ProviderFor(currentNetworkStatus)
final currentNetworkStatusProvider = AutoDisposeProvider<bool>.internal(
  currentNetworkStatus,
  name: r'currentNetworkStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentNetworkStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentNetworkStatusRef = AutoDisposeProviderRef<bool>;
String _$isOfflineFeatureAvailableHash() =>
    r'59e6242c97b5e3772ad7cd3253b3f7e4c7397131';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider to check if specific features should be available based on network status.
///
/// Copied from [isOfflineFeatureAvailable].
@ProviderFor(isOfflineFeatureAvailable)
const isOfflineFeatureAvailableProvider = IsOfflineFeatureAvailableFamily();

/// Provider to check if specific features should be available based on network status.
///
/// Copied from [isOfflineFeatureAvailable].
class IsOfflineFeatureAvailableFamily extends Family<bool> {
  /// Provider to check if specific features should be available based on network status.
  ///
  /// Copied from [isOfflineFeatureAvailable].
  const IsOfflineFeatureAvailableFamily();

  /// Provider to check if specific features should be available based on network status.
  ///
  /// Copied from [isOfflineFeatureAvailable].
  IsOfflineFeatureAvailableProvider call(
    String feature,
  ) {
    return IsOfflineFeatureAvailableProvider(
      feature,
    );
  }

  @override
  IsOfflineFeatureAvailableProvider getProviderOverride(
    covariant IsOfflineFeatureAvailableProvider provider,
  ) {
    return call(
      provider.feature,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'isOfflineFeatureAvailableProvider';
}

/// Provider to check if specific features should be available based on network status.
///
/// Copied from [isOfflineFeatureAvailable].
class IsOfflineFeatureAvailableProvider extends AutoDisposeProvider<bool> {
  /// Provider to check if specific features should be available based on network status.
  ///
  /// Copied from [isOfflineFeatureAvailable].
  IsOfflineFeatureAvailableProvider(
    String feature,
  ) : this._internal(
          (ref) => isOfflineFeatureAvailable(
            ref as IsOfflineFeatureAvailableRef,
            feature,
          ),
          from: isOfflineFeatureAvailableProvider,
          name: r'isOfflineFeatureAvailableProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isOfflineFeatureAvailableHash,
          dependencies: IsOfflineFeatureAvailableFamily._dependencies,
          allTransitiveDependencies:
              IsOfflineFeatureAvailableFamily._allTransitiveDependencies,
          feature: feature,
        );

  IsOfflineFeatureAvailableProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.feature,
  }) : super.internal();

  final String feature;

  @override
  Override overrideWith(
    bool Function(IsOfflineFeatureAvailableRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsOfflineFeatureAvailableProvider._internal(
        (ref) => create(ref as IsOfflineFeatureAvailableRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        feature: feature,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _IsOfflineFeatureAvailableProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsOfflineFeatureAvailableProvider &&
        other.feature == feature;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, feature.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsOfflineFeatureAvailableRef on AutoDisposeProviderRef<bool> {
  /// The parameter `feature` of this provider.
  String get feature;
}

class _IsOfflineFeatureAvailableProviderElement
    extends AutoDisposeProviderElement<bool> with IsOfflineFeatureAvailableRef {
  _IsOfflineFeatureAvailableProviderElement(super.provider);

  @override
  String get feature => (origin as IsOfflineFeatureAvailableProvider).feature;
}

String _$networkStatusHash() => r'6a88840160e0aed4ca833f2ff5df4dac713b3454';

/// A `StreamNotifier` that manages and exposes the device's network connection status.
///
/// It correctly overrides the `build` method by returning a `Stream<bool>`.
///
/// Copied from [NetworkStatus].
@ProviderFor(NetworkStatus)
final networkStatusProvider =
    StreamNotifierProvider<NetworkStatus, bool>.internal(
  NetworkStatus.new,
  name: r'networkStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NetworkStatus = StreamNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
