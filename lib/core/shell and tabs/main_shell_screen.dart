import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qvise/features/content/presentation/providers/tab_navigation_provider.dart';
import 'browse_tab.dart';
import 'create_tab.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'profile_tab.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

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
        automaticallyImplyLeading: false, // No back button in main shell
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(currentTabIndexProvider.notifier).state = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}