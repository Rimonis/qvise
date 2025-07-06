// lib/core/providers/network_status_provider.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_status_provider.g.dart';

@Riverpod(keepAlive: true)
class NetworkCallbacks extends _$NetworkCallbacks {
  final List<VoidCallback> _onOnlineCallbacks = [];

  @override
  void build() {}

  void addOnlineCallback(VoidCallback callback) {
    _onOnlineCallbacks.add(callback);
  }

  void notifyOnline() {
    for (final callback in _onOnlineCallbacks) {
      callback();
    }
  }
}

@Riverpod(keepAlive: true)
class NetworkStatus extends _$NetworkStatus {
  StreamSubscription? _connectivitySubscription;
  Timer? _periodicTimer;

  @override
  Stream<bool> build() {
    final controller = StreamController<bool>.broadcast();

    _checkConnection().then((value) {
      if (!controller.isClosed) controller.add(value);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) async {
      final isConnected = await _checkConnection();
      if (!controller.isClosed) {
        controller.add(isConnected);
        if (isConnected) {
          ref.read(networkCallbacksProvider.notifier).notifyOnline();
        }
      }
    });

    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!controller.isClosed) {
        final isConnected = await _checkConnection();
        controller.add(isConnected);
      }
    });

    ref.onDispose(() {
      _connectivitySubscription?.cancel();
      _periodicTimer?.cancel();
      controller.close();
    });

    return controller.stream;
  }

  Future<bool> _checkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return false;
      return await InternetConnectionChecker().hasConnection;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkNow() async {
    ref.invalidateSelf();
  }
}