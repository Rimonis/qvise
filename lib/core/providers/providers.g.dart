// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$internetConnectionCheckerHash() =>
    r'df4afdae9b1254033a9c75f8b93312a85bad1502';

/// See also [internetConnectionChecker].
@ProviderFor(internetConnectionChecker)
final internetConnectionCheckerProvider =
    Provider<InternetConnectionChecker>.internal(
  internetConnectionChecker,
  name: r'internetConnectionCheckerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$internetConnectionCheckerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InternetConnectionCheckerRef = ProviderRef<InternetConnectionChecker>;
String _$firebaseInitializationHash() =>
    r'be01d8736196c80ad7bf70842e15610021778422';

/// See also [firebaseInitialization].
@ProviderFor(firebaseInitialization)
final firebaseInitializationProvider = FutureProvider<void>.internal(
  firebaseInitialization,
  name: r'firebaseInitializationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseInitializationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseInitializationRef = FutureProviderRef<void>;
String _$firebaseAuthHash() => r'dffd78b4e77d56a1066f36e3d8d40a004d636084';

/// See also [firebaseAuth].
@ProviderFor(firebaseAuth)
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseAuthRef = ProviderRef<firebase_auth.FirebaseAuth>;
String _$firebaseFirestoreHash() => r'da44e0544482927855093596d84cb41842b27214';

/// See also [firebaseFirestore].
@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider = Provider<FirebaseFirestore>.internal(
  firebaseFirestore,
  name: r'firebaseFirestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseFirestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseFirestoreRef = ProviderRef<FirebaseFirestore>;
String _$googleSignInHash() => r'16fd9d9d451285bf82611c0cf70ed2172e74f0ea';

/// See also [googleSignIn].
@ProviderFor(googleSignIn)
final googleSignInProvider = Provider<GoogleSignIn>.internal(
  googleSignIn,
  name: r'googleSignInProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$googleSignInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoogleSignInRef = ProviderRef<GoogleSignIn>;
String _$authStateChangesHash() => r'f01ce67b236527169625e05eb213da2b7ad317ba';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = StreamProvider<firebase_auth.User?>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = StreamProviderRef<firebase_auth.User?>;
String _$currentUserHash() => r'5204d57ed00767795248997d5121ce13f02c3af0';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = Provider<AsyncValue<firebase_auth.User?>>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = ProviderRef<AsyncValue<firebase_auth.User?>>;
String _$isAuthenticatedHash() => r'19e3e08e57b6375be3cbfa8cf38d7b28b674d7d0';

/// See also [isAuthenticated].
@ProviderFor(isAuthenticated)
final isAuthenticatedProvider = AutoDisposeProvider<bool>.internal(
  isAuthenticated,
  name: r'isAuthenticatedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isAuthenticatedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAuthenticatedRef = AutoDisposeProviderRef<bool>;
String _$authLocalDataSourceHash() =>
    r'036987efae0d09a58f68a6556bf18cbd6d1b560b';

/// See also [authLocalDataSource].
@ProviderFor(authLocalDataSource)
final authLocalDataSourceProvider =
    FutureProvider<AuthLocalDataSource>.internal(
  authLocalDataSource,
  name: r'authLocalDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authLocalDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthLocalDataSourceRef = FutureProviderRef<AuthLocalDataSource>;
String _$authRemoteDataSourceHash() =>
    r'4a5b4ce2795b01fbaa743319550e37c996c2a3a6';

/// See also [authRemoteDataSource].
@ProviderFor(authRemoteDataSource)
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>.internal(
  authRemoteDataSource,
  name: r'authRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRemoteDataSourceRef = ProviderRef<AuthRemoteDataSource>;
String _$authRepositoryHash() => r'abdaf81684e2c53717f3a92ee64aee91b9945022';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = FutureProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = FutureProviderRef<AuthRepository>;
String _$getCurrentUserHash() => r'0d97e2c07cacd84619bf01b912f574250eae538f';

/// See also [getCurrentUser].
@ProviderFor(getCurrentUser)
final getCurrentUserProvider = FutureProvider<GetCurrentUser>.internal(
  getCurrentUser,
  name: r'getCurrentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getCurrentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetCurrentUserRef = FutureProviderRef<GetCurrentUser>;
String _$signInWithEmailPasswordHash() =>
    r'28126832987fc0a48c68902584c53f2cd032a64c';

/// See also [signInWithEmailPassword].
@ProviderFor(signInWithEmailPassword)
final signInWithEmailPasswordProvider =
    FutureProvider<SignInWithEmailPassword>.internal(
  signInWithEmailPassword,
  name: r'signInWithEmailPasswordProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$signInWithEmailPasswordHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignInWithEmailPasswordRef = FutureProviderRef<SignInWithEmailPassword>;
String _$signUpWithEmailPasswordHash() =>
    r'a5827a5c4a03f533170cdf727f28c2580f875471';

/// See also [signUpWithEmailPassword].
@ProviderFor(signUpWithEmailPassword)
final signUpWithEmailPasswordProvider =
    FutureProvider<SignUpWithEmailPassword>.internal(
  signUpWithEmailPassword,
  name: r'signUpWithEmailPasswordProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$signUpWithEmailPasswordHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignUpWithEmailPasswordRef = FutureProviderRef<SignUpWithEmailPassword>;
String _$signInWithGoogleHash() => r'5de2f7dd3735891c202fbb3a384cd82eed1f0371';

/// See also [signInWithGoogle].
@ProviderFor(signInWithGoogle)
final signInWithGoogleProvider = FutureProvider<SignInWithGoogle>.internal(
  signInWithGoogle,
  name: r'signInWithGoogleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$signInWithGoogleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignInWithGoogleRef = FutureProviderRef<SignInWithGoogle>;
String _$signOutHash() => r'a229ddde205cb1934bc31dd67cb4bb37fe9c6579';

/// See also [signOut].
@ProviderFor(signOut)
final signOutProvider = FutureProvider<SignOut>.internal(
  signOut,
  name: r'signOutProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$signOutHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SignOutRef = FutureProviderRef<SignOut>;
String _$sendEmailVerificationHash() =>
    r'8c034c464157ad36604a2165854e7739bf59df95';

/// See also [sendEmailVerification].
@ProviderFor(sendEmailVerification)
final sendEmailVerificationProvider =
    FutureProvider<SendEmailVerification>.internal(
  sendEmailVerification,
  name: r'sendEmailVerificationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendEmailVerificationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SendEmailVerificationRef = FutureProviderRef<SendEmailVerification>;
String _$checkEmailVerificationHash() =>
    r'7eddc94ebf05d69b1d4eb58f83e5e681bd01d2e4';

/// See also [checkEmailVerification].
@ProviderFor(checkEmailVerification)
final checkEmailVerificationProvider =
    FutureProvider<CheckEmailVerification>.internal(
  checkEmailVerification,
  name: r'checkEmailVerificationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkEmailVerificationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CheckEmailVerificationRef = FutureProviderRef<CheckEmailVerification>;
String _$resetPasswordHash() => r'129639d09819e179a25c50a24e561367ead30de2';

/// See also [resetPassword].
@ProviderFor(resetPassword)
final resetPasswordProvider = FutureProvider<ResetPassword>.internal(
  resetPassword,
  name: r'resetPasswordProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$resetPasswordHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResetPasswordRef = FutureProviderRef<ResetPassword>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
