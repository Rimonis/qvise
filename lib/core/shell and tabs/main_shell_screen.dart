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

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> with TickerProviderStateMixin {
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

  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(currentTabIndexProvider);
    final NavigatorState? navigator = _navigatorKeys[currentIndex].currentState;
    
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    
    if (currentIndex != 2) {
      ref.read(currentTabIndexProvider.notifier).state = 2;
      _pageController.jumpToPage(2);
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

  void _onTabSelected(int index) {
    ref.read(currentTabIndexProvider.notifier).state = index;
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
    
    final currentIndex = ref.watch(currentTabIndexProvider);
    final syncState = ref.watch(syncCoordinatorProvider);

    final List<Widget> tabs = [
      Navigator(key: _navigatorKeys[0], onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const BrowseTab())),
      Navigator(key: _navigatorKeys[1], onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const CreateTab())),
      Navigator(key: _navigatorKeys[2], onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const HomeTab())),
      Navigator(key: _navigatorKeys[3], onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const AnalyticsTab())),
      Navigator(key: _navigatorKeys[4], onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => const ProfileTab())),
    ];

    final List<String> tabTitles = ['Browse', 'Create', 'Home', 'Analytics', 'Profile'];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabTitles[currentIndex]),
          centerTitle: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: syncState.when(
                idle: () => const SizedBox.shrink(),
                syncing: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                success: () => const Icon(Icons.check_circle, color: Colors.green),
                error: (message) => Tooltip(
                  message: message,
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onTabSelected,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Browse', tooltip: 'Browse lessons'),
            NavigationDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: 'Create', tooltip: 'Create and edit lessons'),
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home', tooltip: 'Due lessons'),
            NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics', tooltip: 'View analytics'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile', tooltip: 'Your profile'),
          ],
        ),
      ),
    );
  }
}