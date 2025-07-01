import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'network_status_provider.g.dart';

// This class-based notifier generates 'networkStatusProvider'.
@Riverpod(keepAlive: true)
class NetworkStatus extends _$NetworkStatus {
  final StreamController<bool> _controller = StreamController<bool>();
  StreamSubscription? _connectivitySubscription;

  @override
  Stream<bool> build() {
    _checkConnection().then((value) {
      if (!_controller.isClosed) {
        _controller.add(value);
      }
    });

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) async {
      if (!_controller.isClosed) {
        _controller.add(await _checkConnection());
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _controller.close();
    });

    return _controller.stream;
  }

  Future<bool> _checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      return await InternetConnectionChecker().hasConnection;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkNow() async {
    if (!_controller.isClosed) {
      _controller.add(await _checkConnection());
    }
  }
}

// FIX: This function was renamed from 'networkStatus' to 'currentNetworkStatus'
// to resolve the name collision. It now correctly generates 'currentNetworkStatusProvider'.
@riverpod
bool currentNetworkStatus(Ref ref) {
  return ref.watch(networkStatusProvider).value ?? false;
}

@riverpod
bool isOfflineFeatureAvailable(Ref ref, String feature) {
  // This now correctly watches the derived provider.
  final isOnline = ref.watch(currentNetworkStatusProvider);

  const offlineFeatures = {
    'browse_lessons',
    'view_profile',
    'view_analytics',
  };

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

  return isOnline;
}

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
    final networkStatusAsync = ref.watch(networkStatusProvider);

    return networkStatusAsync.when(
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
                        const Icon(Icons.wifi_off,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'No internet connection',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref
                                .read(networkStatusProvider.notifier)
                                .checkNow();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
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