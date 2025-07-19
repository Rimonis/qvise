// lib/core/services/subscription_service.dart
enum SubscriptionTier { free, premium }

abstract class SubscriptionService {
  Future<bool> hasActiveSubscription();
  Future<SubscriptionTier> getCurrentTier();
  Stream<SubscriptionTier> get tierStream;
}

class MockSubscriptionService implements SubscriptionService {
  // In a real app, this would check RevenueCat, Play Store, etc.
  // For testing, we can toggle this value.
  bool _isPremium = false; 

  @override
  Future<bool> hasActiveSubscription() async {
    return _isPremium;
  }

  @override
  Future<SubscriptionTier> getCurrentTier() async {
    return _isPremium ? SubscriptionTier.premium : SubscriptionTier.free;
  }
  
  @override
  Stream<SubscriptionTier> get tierStream async* {
    yield await getCurrentTier();
  }

  // Helper for testing
  void setPremium(bool isPremium) {
    _isPremium = isPremium;
  }
}