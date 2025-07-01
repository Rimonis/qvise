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
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize navigator keys for each tab
    _navigatorKeys = List.generate(5, (index) => GlobalKey<NavigatorState>());
    
    // Initialize page controller
    final initialIndex = ref.read(currentTabIndexProvider);
    _pageController = PageController(initialPage: initialIndex);
    
    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Show FAB for create tab
    if (initialIndex == 1) {
      _fabAnimationController.forward();
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
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
    
    // Handle FAB animation
    if (index == 1) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        // Floating action button for create tab
        floatingActionButton: currentIndex == 1
            ? ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Navigate to subject selection
                    final navigator = _navigatorKeys[1].currentState;
                    if (navigator != null) {
                      // This would push the subject selection screen
                      // For now, just show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigate to subject selection'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Lesson'),
                  tooltip: 'Create new lesson',
                ),
              )
            : null,
      ),
    );
  }
}

// Alternative implementation using IndexedStack (simpler but keeps all tabs in memory)
class MainShellScreenSimple extends ConsumerWidget {
  const MainShellScreenSimple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);

    final List<Widget> tabs = [
      const BrowseTab(),
      const CreateTab(),
      const HomeTab(),
      const AnalyticsTab(),
      const ProfileTab(),
    ];

    final List<String> tabTitles = [
      'Browse',
      'Create', 
      'Home',
      'Analytics',
      'Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tabTitles[currentIndex]),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}