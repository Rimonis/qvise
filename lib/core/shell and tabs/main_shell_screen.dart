// lib/core/shell and tabs/main_shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_coordinator.dart';
import 'package:qvise/core/application/sync_state.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'browse_tab.dart';
import 'create_tab.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'profile_tab.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);
    final syncState = ref.watch(syncCoordinatorProvider);

    final List<Widget> tabs =;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(currentIndex)),
        centerTitle: true,
        actions:,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(currentTabIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.primaryColor,
        unselectedItemColor: context.textSecondaryColor,
        items: const,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case TabIndex.browse:
        return 'Browse Content';
      case TabIndex.create:
        return 'Create';
      case TabIndex.home:
        return 'Home';
      case TabIndex.analytics:
        return 'Analytics';
      case TabIndex.profile:
        return 'Profile';
      default:
        return 'Qvise';
    }
  }

  Widget _buildSyncStatusIcon(BuildContext context, SyncState syncState) {
    return syncState.when(
      idle: () => const SizedBox.shrink(),
      syncing: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
      success: () => Icon(Icons.check_circle_outline, color: context.successColor),
      failure: (_) => Icon(Icons.error_outline, color: context.errorColor),
    );
  }
}