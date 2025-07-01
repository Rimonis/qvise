import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_status_provider.g.dart';

@Riverpod(keepAlive: true)
class NetworkStatus extends _$NetworkStatus {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicCheck;

  @override
  Stream<bool> build() async* {
    // Clean up on dispose
    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _periodicCheck?.cancel();
    });

    // Initial check
    yield await _checkConnection();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        // When connectivity changes, verify actual internet connection
        final hasInternet = await _checkConnection();
        state = AsyncValue.data(hasInternet);
      },
    );

    // Periodic check every 30 seconds to verify internet access
    _periodicCheck = Timer.periodic(const Duration(seconds: 30), (_) async {
      final hasInternet = await _checkConnection();
      if (state.value != hasInternet) {
        state = AsyncValue.data(hasInternet);
      }
    });

    // Yield connectivity status changes
    yield* state.when(
      data: (value) => Stream.value(value),
      loading: () => Stream.value(false),
      error: (_, __) => Stream.value(false),
    );
  }

  Future<bool> _checkConnection() async {
    try {
      // First check if we have any connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Then verify actual internet connection
      return await _connectionChecker.hasConnection;
    } catch (e) {
      // If check fails, assume no connection
      return false;
    }
  }

  Future<bool> checkNow() async {
    final hasInternet = await _checkConnection();
    state = AsyncValue.data(hasInternet);
    return hasInternet;
  }
}

// Simple provider for current network status
@riverpod
bool networkStatus(NetworkStatusRef ref) {
  return ref.watch(networkStatusProvider).valueOrNull ?? false;
}

// Provider to check if specific features should be available offline
@riverpod
bool isOfflineFeatureAvailable(IsOfflineFeatureAvailableRef ref, String feature) {
  final isOnline = ref.watch(networkStatusProvider).valueOrNull ?? false;
  
  // Define which features are available offline
  const offlineFeatures = {
    'browse_lessons',  // Can browse cached lessons
    'view_profile',    // Can view cached profile
    'view_analytics',  // Can view cached analytics
  };
  
  // Features that require internet
  const onlineOnlyFeatures = {
    'create_lesson',
    'edit_lesson',
    'lock_lessons',
    'sync_data',
    'google_sign_in',
    'email_verification',
  };
  
  if (onlineOnlyFeatures.contains(feature)) {
    return isOnline;
  }
  
  if (offlineFeatures.contains(feature)) {
    return true;
  }
  
  // Default to requiring internet
  return isOnline;
}

// Network aware wrapper widget
class NetworkAware extends ConsumerWidget {
  final Widget child;
  final Widget? offlineChild;
  final bool showBanner;

  const NetworkAware({
    super.key,
    required this.child,
    this.offlineChild,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return networkStatus.when(
      data: (isOnline) {
        if (!isOnline && offlineChild != null) {
          return offlineChild!;
        }

        if (showBanner && !isOnline) {
          return Column(
            children: [
              Material(
                color: Colors.orange,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'No internet connection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref.read(networkStatusProvider.notifier).checkNow();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          );
        }

        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }
}