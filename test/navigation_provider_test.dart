import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/presentation/providers/navigation_provider.dart';

void main() {
  group('NavigationNotifier tab order', () {
    test(
      'indices match HomePage: Dashboard, Logs, Errors, Services, Settings',
      () {
        final nav = NavigationNotifier();

        expect(nav.state, NavIndex.dashboard);
        expect(NavIndex.count, 5);

        nav.goToLogs();
        expect(nav.state, NavIndex.logs);

        nav.goToErrors();
        expect(nav.state, NavIndex.errors);

        nav.goToServices();
        expect(nav.state, NavIndex.services);
        expect(nav.state, 3);

        nav.goToSettings();
        expect(nav.state, NavIndex.settings);
        expect(nav.state, 4);

        nav.goToDashboard();
        expect(nav.state, 0);
      },
    );

    test('ignores out-of-range indices', () {
      final nav = NavigationNotifier();
      nav.setIndex(99);
      expect(nav.state, NavIndex.dashboard);
      nav.setIndex(-1);
      expect(nav.state, NavIndex.dashboard);
      // Index 4 is settings (valid); 5 is out of range
      nav.setIndex(5);
      expect(nav.state, NavIndex.dashboard);
    });
  });
}
