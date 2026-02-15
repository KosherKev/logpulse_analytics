import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation State Provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

/// Navigation Notifier
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    if (index >= 0 && index < 4) {
      state = index;
    }
  }

  void goToDashboard() => setIndex(0);
  void goToErrors() => setIndex(1);
  void goToLogs() => setIndex(2);
  void goToSettings() => setIndex(3);
}

/// Current Page Index Provider
final currentPageIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider);
});
