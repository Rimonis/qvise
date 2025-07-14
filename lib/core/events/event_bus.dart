// lib/core/events/event_bus.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain_event.dart';

/// Provider for the global event bus
final eventBusProvider = Provider<EventBus>((ref) {
  return EventBus();
});

/// Simple event bus implementation for domain events
class EventBus {
  final Map<Type, StreamController> _controllers = {};
  final Map<Type, Stream> _streams = {};

  /// Subscribe to events of a specific type
  Stream<T> on<T extends DomainEvent>() {
    final type = T;
    
    if (!_streams.containsKey(type)) {
      _controllers[type] = StreamController<T>.broadcast();
      _streams[type] = _controllers[type]!.stream as Stream<T>;
    }
    
    return _streams[type] as Stream<T>;
  }

  /// Subscribe to all domain events
  Stream<DomainEvent> onAll() {
    return on<DomainEvent>();
  }

  /// Publish an event
  void publish<T extends DomainEvent>(T event) {
    // Publish to specific type stream
    final type = T;
    if (_controllers.containsKey(type)) {
      _controllers[type]!.add(event);
    }

    // Also publish to general DomainEvent stream
    if (type != DomainEvent && _controllers.containsKey(DomainEvent)) {
      _controllers[DomainEvent]!.add(event);
    }
  }

  /// Dispose all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _streams.clear();
  }

  /// Get active subscription count for debugging
  int get activeSubscriptions => _controllers.length;
}

/// Event bus extensions for common operations
extension EventBusExtensions on EventBus {
  /// Publish multiple events in sequence
  void publishAll(List<DomainEvent> events) {
    for (final event in events) {
      publish(event);
    }
  }

  /// Subscribe to multiple event types
  Stream<DomainEvent> onAny<T1 extends DomainEvent, T2 extends DomainEvent>() {
    return StreamGroup.merge([
      on<T1>(),
      on<T2>(),
    ]);
  }
}

/// Helper class for merging streams
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late StreamController<T> controller;
    List<StreamSubscription<T>> subscriptions = [];

    controller = StreamController<T>(
      onListen: () {
        for (final stream in streams) {
          subscriptions.add(
            stream.listen(
              controller.add,
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }
}
