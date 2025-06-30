import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the current tab index
final currentTabIndexProvider = StateProvider<int>((ref) => 2); // Start with Home tab (index 2)

// Helper extension for tab indices
extension TabIndex on int {
  static const browse = 0;
  static const create = 1;
  static const home = 2;
  static const analytics = 3;
  static const profile = 4;
}