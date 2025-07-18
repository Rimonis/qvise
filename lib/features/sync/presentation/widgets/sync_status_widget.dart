// lib/features/sync/presentation/widgets/sync_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_coordinator.dart';
import 'package:qvise/core/application/sync_state.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncCoordinatorProvider);
    return Card(
      child: ListTile(
        leading: _buildIcon(syncState),
        title: Text(_getTitle(syncState)),
        subtitle: _buildSubtitle(context, syncState),
        trailing: _buildTrailing(context, syncState, ref),
      ),
    );
  }

  Widget _buildIcon(SyncState state) {
    return state.when(
      idle: () => const Icon(Icons.cloud_done),
      syncing: () => const CircularProgressIndicator(strokeWidth: 2),
      success: (_) => const Icon(Icons.check_circle, color: Colors.green),
      error: (_) => const Icon(Icons.error, color: Colors.red),
      hasConflicts: (_) => const Icon(Icons.warning, color: Colors.orange),
    );
  }

  String _getTitle(SyncState state) {
    return state.when(
      idle: () => 'Synced',
      syncing: () => 'Syncing...',
      success: (report) => 'Sync Complete',
      error: (failure) => 'Sync Failed',
      hasConflicts: (conflicts) => '${conflicts.length} Conflicts',
    );
  }

  Widget? _buildSubtitle(BuildContext context, SyncState state) {
    return state.maybeWhen(
      error: (failure) => Text(failure.userFriendlyMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
      orElse: () => null,
    );
  }

  Widget? _buildTrailing(
      BuildContext context, SyncState state, WidgetRef ref) {
    return state.maybeWhen(
      hasConflicts: (conflicts) => ElevatedButton(
        onPressed: () {
          // Navigate to conflict resolution screen
        },
        child: const Text('Resolve'),
      ),
      error: (_) => IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => ref.read(syncCoordinatorProvider.notifier).syncAll(),
      ),
      orElse: () => null,
    );
  }
}
