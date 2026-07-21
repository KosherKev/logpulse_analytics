import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/presentation/providers/navigation_provider.dart';

void main() {
  group('NavigationNotifier tab order', () {
    test('indices match HomePage: Dashboard, Logs, Errors, Settings', () {
      final nav = NavigationNotifier();

      expect(nav.state, NavIndex.dashboard);

      nav.goToLogs();
      expect(nav.state, 1);

      nav.goToErrors();
      expect(nav.state, 2);

      nav.goToSettings();
      expect(nav.state, 3);

      nav.goToDashboard();
      expect(nav.state, 0);
    });

    test('ignores out-of-range indices', () {
      final nav = NavigationNotifier();
      nav.setIndex(99);
      expect(nav.state, NavIndex.dashboard);
      nav.setIndex(-1);
      expect(nav.state, NavIndex.dashboard);
    });
  });
}
