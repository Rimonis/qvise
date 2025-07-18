// lib/core/sync/services/remote_entity_cache.dart

class RemoteEntityCache {
  final _cache = <String, CachedEntity>{};
  final Duration cacheDuration;

  RemoteEntityCache({this.cacheDuration = const Duration(minutes: 5)});

  T? get<T>(String id) {
    final cached = _cache[id];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > cacheDuration) {
      _cache.remove(id);
      return null;
    }
    return cached.data as T;
  }

  void put(String id, dynamic data) {
    _cache[id] = CachedEntity(
      data: data,
      cachedAt: DateTime.now(),
    );
  }

  void putAll(Map<String, dynamic> items) {
    final now = DateTime.now();
    items.forEach((id, data) {
      _cache[id] = CachedEntity(data: data, cachedAt: now);
    });
  }

  void clear() => _cache.clear();
}

class CachedEntity {
  final dynamic data;
  final DateTime cachedAt;
  CachedEntity({required this.data, required this.cachedAt});
}
