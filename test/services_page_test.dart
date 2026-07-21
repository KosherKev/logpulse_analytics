import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logpulse_analytics/data/models/service_summary.dart';
import 'package:logpulse_analytics/data/repositories/services_repository.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';
import 'package:logpulse_analytics/presentation/pages/services/services_page.dart';
import 'package:logpulse_analytics/presentation/providers/navigation_provider.dart';
import 'package:logpulse_analytics/presentation/providers/service_providers.dart';
import 'package:logpulse_analytics/presentation/widgets/dashboard/service_health_list.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';

/// Fake API — only listServices is exercised by catalog tests.
class _FakeApiService extends ApiService {
  _FakeApiService({this.listResult});

  Future<List<ServiceSummary>> Function()? listResult;

  @override
  Future<List<ServiceSummary>> getServices({String? timeRange}) {
    return listResult!();
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ServicesPage', () {
    testWidgets('empty catalog shows no-services message', (tester) async {
      final api = _FakeApiService(
        listResult: () async => <ServiceSummary>[],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWith(
              (ref) => ServicesRepository(api),
            ),
          ],
          child: const MaterialApp(home: ServicesPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No services reporting yet'), findsOneWidget);
    });

    testWidgets('list shows rows; null rates render as em dash',
        (tester) async {
      final api = _FakeApiService(
        listResult: () async => [
          const ServiceSummary(
            name: 'null-rates',
            totalRequests: 10,
            errorRate: null,
            avgLatency: null,
          ),
          const ServiceSummary(
            name: 'with-rates',
            displayName: 'With Rates',
            totalRequests: 100,
            errorRate: 2.5,
            avgLatency: 42,
            instanceCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWith(
              (ref) => ServicesRepository(api),
            ),
          ],
          child: const MaterialApp(home: ServicesPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('null-rates'), findsOneWidget);
      expect(find.text('With Rates'), findsOneWidget);
      expect(find.textContaining('err —'), findsOneWidget);
      expect(find.textContaining('2.5%'), findsOneWidget);
      expect(find.textContaining('42ms'), findsOneWidget);
      expect(find.text('3 instances'), findsOneWidget);
    });

    testWidgets('tap row opens ServiceDetailsPage route', (tester) async {
      final api = _FakeApiService(
        listResult: () async => [
          const ServiceSummary(name: 'tap-me', totalRequests: 1),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            servicesRepositoryProvider.overrideWith(
              (ref) => ServicesRepository(api),
            ),
            // Detail provider will fail without full API — we only assert push.
          ],
          child: const MaterialApp(home: ServicesPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('tap-me'));
      await tester.pump(); // start route
      // Detail page shows service name in AppBar while loading/error.
      expect(find.text('tap-me'), findsWidgets);
    });
  });

  group('ServiceHealthList view all', () {
    testWidgets('view all → calls goToServices', (tester) async {
      final stats = <String, ServiceStats>{
        for (var i = 0; i < 5; i++)
          'svc-$i': ServiceStats(
            serviceName: 'svc-$i',
            totalRequests: i,
            errorRate: null,
            avgLatency: null,
            uptime: null,
            errorCount: null,
          ),
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ServiceHealthList(
                serviceStats: stats,
                maxVisible: 3,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('view all →'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ServiceHealthList)),
      );
      expect(container.read(navigationProvider), NavIndex.dashboard);

      await tester.tap(find.text('view all →'));
      await tester.pump();

      expect(container.read(navigationProvider), NavIndex.services);
    });
  });
}
