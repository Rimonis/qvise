// lib/core/sync/utils/batch_helpers.dart

class BatchHelpers {
  static Future<List<T>> batchProcess<S, T>({
    required List<S> items,
    required Future<List<T>> Function(List<S>) processBatch,
    int batchSize = 10,
    bool continueOnError = false,
  }) async {
    final List<T> results = [];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      try {
        final batchResults = await processBatch(batch);
        results.addAll(batchResults);
      } catch (e) {
        if (!continueOnError) rethrow;
        print('Batch processing error: $e');
      }
    }
    
    return results;
  }

  static List<List<T>> createBatches<T>(List<T> items, int batchSize) {
    final List<List<T>> batches = [];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      batches.add(batch);
    }
    
    return batches;
  }
}