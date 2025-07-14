// lib/core/providers/network_status_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'providers.dart';

final networkStatusProvider = AsyncNotifierProvider<NetworkStatusNotifier, bool>(
  NetworkStatusNotifier.new,
);

class NetworkStatusNotifier extends AsyncNotifier<bool> {
  late final InternetConnectionChecker _connectionChecker;
  StreamSubscription? _connectionSubscription;

  @override
  Future<bool> build() async {
    _connectionChecker = ref.watch(internetConnectionCheckerProvider);
    
    // Listen to connection changes
    _connectionSubscription = _connectionChecker.onStatusChange.listen(
      (status) {
        final isConnected = status == InternetConnectionStatus.connected;
        if (mounted) {
          state = AsyncValue.data(isConnected);
        }
      },
    );

    // Get initial connection status
    final hasConnection = await _connectionChecker.hasConnection;
    return hasConnection;
  }

  /// Manually check connection status
  Future<void> checkConnection() async {
    state = const AsyncValue.loading();
    try {
      final hasConnection = await _connectionChecker.hasConnection;
      state = AsyncValue.data(hasConnection);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Force a connection check with retry
  Future<bool> forceCheck({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final hasConnection = await _connectionChecker.hasConnection;
        if (hasConnection) {
          if (mounted) {
            state = AsyncValue.data(true);
          }
          return true;
        }
        
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (i + 1) * 2));
        }
      } catch (e) {
        if (i == maxRetries - 1) {
          if (mounted) {
            state = AsyncValue.error(e, StackTrace.current);
          }
        }
      }
    }
    
    if (mounted) {
      state = const AsyncValue.data(false);
    }
    return false;
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

// Helper extension for easy usage
extension NetworkStatusRef on WidgetRef {
  AsyncValue<bool> get networkStatus => watch(networkStatusProvider);
  bool get isOnline => networkStatus.valueOrNull ?? false;
  bool get isOffline => !isOnline;
}

// Connection quality provider
final connectionQualityProvider = StreamProvider<ConnectionQuality>((ref) {
  final checker = ref.watch(internetConnectionCheckerProvider);
  
  return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
    try {
      final addresses = [
        AddressCheckOptions(
          address: InternetAddress.lookup('google.com'),
          port: 80,
          timeout: const Duration(seconds: 3),
        ),
        AddressCheckOptions(
          address: InternetAddress.lookup('cloudflare.com'),
          port: 80,
          timeout: const Duration(seconds: 3),
        ),
      ];

      final stopwatch = Stopwatch()..start();
      final hasConnection = await checker.hasConnection;
      stopwatch.stop();

      if (!hasConnection) {
        return ConnectionQuality.none;
      }

      final latency = stopwatch.elapsedMilliseconds;
      
      if (latency < 100) {
        return ConnectionQuality.excellent;
      } else if (latency < 300) {
        return ConnectionQuality.good;
      } else if (latency < 600) {
        return ConnectionQuality.fair;
      } else {
        return ConnectionQuality.poor;
      }
    } catch (e) {
      return ConnectionQuality.none;
    }
  });
});

enum ConnectionQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

extension ConnectionQualityExtension on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.none:
        return 'No Connection';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.excellent:
        return 'Excellent';
    }
  }

  bool get canSync {
    return this != ConnectionQuality.none && this != ConnectionQuality.poor;
  }

  Color get color {
    switch (this) {
      case ConnectionQuality.none:
        return Colors.red;
      case ConnectionQuality.poor:
        return Colors.orange;
      case ConnectionQuality.fair:
        return Colors.yellow;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.excellent:
        return Colors.green;
    }
  }
}

// Network status widget
class NetworkStatusIndicator extends ConsumerWidget {
  final bool showQuality;
  final bool showText;

  const NetworkStatusIndicator({
    super.key,
    this.showQuality = false,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    final quality = showQuality ? ref.watch(connectionQualityProvider) : null;

    return networkStatus.when(
      data: (isOnline) {
        if (!isOnline) {
          return _buildStatusChip(
            icon: Icons.cloud_off,
            text: 'Offline',
            color: Colors.red,
          );
        }

        if (quality != null) {
          return quality.when(
            data: (q) => _buildStatusChip(
              icon: Icons.signal_wifi_4_bar,
              text: showText ? q.displayName : null,
              color: q.color,
            ),
            loading: () => _buildStatusChip(
              icon: Icons.signal_wifi_4_bar,
              text: showText ? 'Online' : null,
              color: Colors.green,
            ),
            error: (_, __) => _buildStatusChip(
              icon: Icons.signal_wifi_4_bar,
              text: showText ? 'Online' : null,
              color: Colors.green,
            ),
          );
        }

        return _buildStatusChip(
          icon: Icons.cloud_done,
          text: showText ? 'Online' : null,
          color: Colors.green,
        );
      },
      loading: () => _buildStatusChip(
        icon: Icons.sync,
        text: showText ? 'Checking...' : null,
        color: Colors.grey,
      ),
      error: (_, __) => _buildStatusChip(
        icon: Icons.error,
        text: showText ? 'Error' : null,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    String? text,
    required Color color,
  }) {
    if (!showText || text == null) {
      return Icon(icon, color: color, size: 16);
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}

// Missing imports
import 'dart:io';
import 'package:flutter/material.dart';
