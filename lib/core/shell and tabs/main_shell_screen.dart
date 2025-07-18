// lib/core/shell and tabs/main_shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/core/application/sync_coordinator.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'browse_tab.dart';
import 'create_tab.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'profile_tab.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with TickerProviderStateMixin {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(5, (index) => GlobalKey<NavigatorState>());
    final initialIndex = ref.read(currentTabIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    final currentIndex = ref.read(currentTabIndexProvider);
    final NavigatorState? navigator = _navigatorKeys[currentIndex].currentState;

    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }

    if (currentIndex != 2) { // Home tab index
      ref.read(currentTabIndexProvider.notifier).state = 2;
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.jumpToPage(next);
      }
    });

    final currentIndex = ref.watch(currentTabIndexProvider);
    final syncState = ref.watch(syncCoordinatorProvider);
    final tabs = [
      const BrowseTab(),
      const CreateTab(),
      const HomeTab(),
      const AnalyticsTab(),
      const ProfileTab(),
    ];
    final tabTitles = ['Browse', 'Create', 'Home', 'Analytics', 'Profile'];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _canPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabTitles[currentIndex]),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: syncState.when(
                idle: () => const SizedBox.shrink(),
                syncing: () => const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                success: (_) => const Icon(Icons.check_circle, color: Colors.green),
                error: (failure) => Tooltip(
                  message: failure.userFriendlyMessage,
                  child: const Icon(Icons.error, color: Colors.red),
                ),
                hasConflicts: (conflicts) => Tooltip(
                  message: "${conflicts.length} items have sync conflicts.",
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: tabs.asMap().entries.map((entry) {
            return Navigator(
              key: _navigatorKeys[entry.key],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => entry.value,
              ),
            );
          }).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => ref.read(currentTabIndexProvider.notifier).state = index,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Browse'),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Create'),
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
