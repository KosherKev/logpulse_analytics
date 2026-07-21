import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-nav indices must match [HomePage] page order:
/// 0 Dashboard · 1 Logs · 2 Errors · 3 Settings
abstract final class NavIndex {
  static const dashboard = 0;
  static const logs = 1;
  static const errors = 2;
  static const settings = 3;
  static const count = 4;
}

/// Navigation State Provider
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

/// Navigation Notifier
class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(NavIndex.dashboard);

  void setIndex(int index) {
    if (index >= 0 && index < NavIndex.count) {
      state = index;
    }
  }

  void goToDashboard() => setIndex(NavIndex.dashboard);
  void goToLogs() => setIndex(NavIndex.logs);
  void goToErrors() => setIndex(NavIndex.errors);
  void goToSettings() => setIndex(NavIndex.settings);
}

/// Current Page Index Provider
final currentPageIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider);
});
