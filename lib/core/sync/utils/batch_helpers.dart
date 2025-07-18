// lib/core/sync/utils/batch_helpers.dart

class BatchHelpers {
  static const int firestoreBatchSize = 30;

  static List<List<T>> chunk<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize > list.length) ? list.length : i + chunkSize;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  static Future<List<R>> batchProcess<T, R>({
    required List<T> items,
    required Future<List<R>> Function(List<T> batch) processBatch,
    int batchSize = firestoreBatchSize,
    bool continueOnError = true,
  }) async {
    final results = <R>[];
    final chunks = chunk(items, batchSize);

    for (int i = 0; i < chunks.length; i++) {
      try {
        final batchResults = await processBatch(chunks[i]);
        results.addAll(batchResults);
      } catch (e) {
        print('Batch $i failed: $e');
        if (!continueOnError) rethrow;
      }
    }
    return results;
  }
}
