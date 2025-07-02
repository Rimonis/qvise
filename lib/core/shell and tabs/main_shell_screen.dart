// lib/core/shell and tabs/main_shell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    
    // Initialize navigator keys for each tab
    _navigatorKeys = List.generate(5, (index) => GlobalKey<NavigatorState>());
    
    // Initialize page controller
    final initialIndex = ref.read(currentTabIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle back button navigation within tabs
  Future<bool> _onWillPop() async {
    final currentIndex = ref.read(currentTabIndexProvider);
    final NavigatorState? navigator = _navigatorKeys[currentIndex].currentState;
    
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    
    // If we're not on the home tab, go to home tab
    if (currentIndex != 2) {
      ref.read(currentTabIndexProvider.notifier).state = 2;
      _pageController.jumpToPage(2);
      return false;
    }
    
    // Show exit confirmation
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
    // Update state
    ref.read(currentTabIndexProvider.notifier).state = index;
    
    // Animate to page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to tab changes from other sources (like empty state buttons)
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

    final List<Widget> tabs = [
      Navigator(
        key: _navigatorKeys[0],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const BrowseTab(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[1],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const CreateTab(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[2],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const HomeTab(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[3],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const AnalyticsTab(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[4],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const ProfileTab(),
        ),
      ),
    ];

    final List<String> tabTitles = [
      'Browse',
      'Create',
      'Home',
      'Analytics',
      'Profile',
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tabTitles[currentIndex]),
          centerTitle: true,
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe
          children: tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: _onTabSelected,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Browse',
              tooltip: 'Browse lessons',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit),
              label: 'Create',
              tooltip: 'Create and edit lessons',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
              tooltip: 'Due lessons',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
              tooltip: 'View analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'Your profile',
            ),
          ],
        ),
        // REMOVED: Floating action button for create tab - now handled within CreateTab itself
      ),
    );
  }
}