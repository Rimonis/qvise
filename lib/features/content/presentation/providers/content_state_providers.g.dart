// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_state_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dueLessonsHash() => r'0e2ee6ead76a678a122678ca18663f514f8e857c';

/// See also [dueLessons].
@ProviderFor(dueLessons)
final dueLessonsProvider = AutoDisposeFutureProvider<List<Lesson>>.internal(
  dueLessons,
  name: r'dueLessonsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dueLessonsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DueLessonsRef = AutoDisposeFutureProviderRef<List<Lesson>>;
String _$unlockedLessonsHash() => r'1b3d269ebee8bb3f6b523ed6d3c0474138dfc6fe';

/// See also [unlockedLessons].
@ProviderFor(unlockedLessons)
final unlockedLessonsProvider =
    AutoDisposeFutureProvider<List<Lesson>>.internal(
      unlockedLessons,
      name: r'unlockedLessonsProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$unlockedLessonsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnlockedLessonsRef = AutoDisposeFutureProviderRef<List<Lesson>>;
String _$networkStatusHash() => r'1ee4efaa118fb04b638b078348890b2dcbf7f0b7';

/// See also [networkStatus].
@ProviderFor(networkStatus)
final networkStatusProvider = AutoDisposeStreamProvider<bool>.internal(
  networkStatus,
  name: r'networkStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$networkStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NetworkStatusRef = AutoDisposeStreamProviderRef<bool>;
String _$subjectsNotifierHash() => r'16821f7630a73cf967f43df6ccfca633ae7eea6b';

/// See also [SubjectsNotifier].
@ProviderFor(SubjectsNotifier)
final subjectsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<SubjectsNotifier, List<Subject>>.internal(
      SubjectsNotifier.new,
      name: r'subjectsNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$subjectsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SubjectsNotifier = AutoDisposeAsyncNotifier<List<Subject>>;
String _$topicsNotifierHash() => r'af47a655d3cdb88f6bc8f89506b0fba25ddc3d39';

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

abstract class _$TopicsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Topic>> {
  late final String subjectName;

  FutureOr<List<Topic>> build(String subjectName);
}

/// See also [TopicsNotifier].
@ProviderFor(TopicsNotifier)
const topicsNotifierProvider = TopicsNotifierFamily();

/// See also [TopicsNotifier].
class TopicsNotifierFamily extends Family<AsyncValue<List<Topic>>> {
  /// See also [TopicsNotifier].
  const TopicsNotifierFamily();

  /// See also [TopicsNotifier].
  TopicsNotifierProvider call(String subjectName) {
    return TopicsNotifierProvider(subjectName);
  }

  @override
  TopicsNotifierProvider getProviderOverride(
    covariant TopicsNotifierProvider provider,
  ) {
    return call(provider.subjectName);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'topicsNotifierProvider';
}

/// See also [TopicsNotifier].
class TopicsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TopicsNotifier, List<Topic>> {
  /// See also [TopicsNotifier].
  TopicsNotifierProvider(String subjectName)
    : this._internal(
        () => TopicsNotifier()..subjectName = subjectName,
        from: topicsNotifierProvider,
        name: r'topicsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$topicsNotifierHash,
        dependencies: TopicsNotifierFamily._dependencies,
        allTransitiveDependencies:
            TopicsNotifierFamily._allTransitiveDependencies,
        subjectName: subjectName,
      );

  TopicsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectName,
  }) : super.internal();

  final String subjectName;

  @override
  FutureOr<List<Topic>> runNotifierBuild(covariant TopicsNotifier notifier) {
    return notifier.build(subjectName);
  }

  @override
  Override overrideWith(TopicsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TopicsNotifierProvider._internal(
        () => create()..subjectName = subjectName,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectName: subjectName,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TopicsNotifier, List<Topic>>
  createElement() {
    return _TopicsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TopicsNotifierProvider && other.subjectName == subjectName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TopicsNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Topic>> {
  /// The parameter `subjectName` of this provider.
  String get subjectName;
}

class _TopicsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TopicsNotifier, List<Topic>>
    with TopicsNotifierRef {
  _TopicsNotifierProviderElement(super.provider);

  @override
  String get subjectName => (origin as TopicsNotifierProvider).subjectName;
}

String _$lessonsNotifierHash() => r'7d835e5490796c547b04b503b6c3d60e28cf0f6d';

abstract class _$LessonsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Lesson>> {
  late final String subjectName;
  late final String topicName;

  FutureOr<List<Lesson>> build(String subjectName, String topicName);
}

/// See also [LessonsNotifier].
@ProviderFor(LessonsNotifier)
const lessonsNotifierProvider = LessonsNotifierFamily();

/// See also [LessonsNotifier].
class LessonsNotifierFamily extends Family<AsyncValue<List<Lesson>>> {
  /// See also [LessonsNotifier].
  const LessonsNotifierFamily();

  /// See also [LessonsNotifier].
  LessonsNotifierProvider call(String subjectName, String topicName) {
    return LessonsNotifierProvider(subjectName, topicName);
  }

  @override
  LessonsNotifierProvider getProviderOverride(
    covariant LessonsNotifierProvider provider,
  ) {
    return call(provider.subjectName, provider.topicName);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lessonsNotifierProvider';
}

/// See also [LessonsNotifier].
class LessonsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<LessonsNotifier, List<Lesson>> {
  /// See also [LessonsNotifier].
  LessonsNotifierProvider(String subjectName, String topicName)
    : this._internal(
        () =>
            LessonsNotifier()
              ..subjectName = subjectName
              ..topicName = topicName,
        from: lessonsNotifierProvider,
        name: r'lessonsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$lessonsNotifierHash,
        dependencies: LessonsNotifierFamily._dependencies,
        allTransitiveDependencies:
            LessonsNotifierFamily._allTransitiveDependencies,
        subjectName: subjectName,
        topicName: topicName,
      );

  LessonsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.subjectName,
    required this.topicName,
  }) : super.internal();

  final String subjectName;
  final String topicName;

  @override
  FutureOr<List<Lesson>> runNotifierBuild(covariant LessonsNotifier notifier) {
    return notifier.build(subjectName, topicName);
  }

  @override
  Override overrideWith(LessonsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LessonsNotifierProvider._internal(
        () =>
            create()
              ..subjectName = subjectName
              ..topicName = topicName,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        subjectName: subjectName,
        topicName: topicName,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<LessonsNotifier, List<Lesson>>
  createElement() {
    return _LessonsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonsNotifierProvider &&
        other.subjectName == subjectName &&
        other.topicName == topicName;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, subjectName.hashCode);
    hash = _SystemHash.combine(hash, topicName.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonsNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Lesson>> {
  /// The parameter `subjectName` of this provider.
  String get subjectName;

  /// The parameter `topicName` of this provider.
  String get topicName;
}

class _LessonsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<LessonsNotifier, List<Lesson>>
    with LessonsNotifierRef {
  _LessonsNotifierProviderElement(super.provider);

  @override
  String get subjectName => (origin as LessonsNotifierProvider).subjectName;
  @override
  String get topicName => (origin as LessonsNotifierProvider).topicName;
}

String _$selectedSubjectHash() => r'd811d65905ecdd183cecf2f12e037701dcbcef59';

/// See also [SelectedSubject].
@ProviderFor(SelectedSubject)
final selectedSubjectProvider =
    AutoDisposeNotifierProvider<SelectedSubject, Subject?>.internal(
      SelectedSubject.new,
      name: r'selectedSubjectProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedSubjectHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedSubject = AutoDisposeNotifier<Subject?>;
String _$selectedTopicHash() => r'696878546c17ea51a533ded1085eeb00c6744dbd';

/// See also [SelectedTopic].
@ProviderFor(SelectedTopic)
final selectedTopicProvider =
    AutoDisposeNotifierProvider<SelectedTopic, Topic?>.internal(
      SelectedTopic.new,
      name: r'selectedTopicProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$selectedTopicHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SelectedTopic = AutoDisposeNotifier<Topic?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
