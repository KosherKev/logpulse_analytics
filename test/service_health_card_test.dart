import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';
import 'package:logpulse_analytics/presentation/widgets/cards/service_health_card.dart';

void main() {
  setUpAll(() {
    // Avoid hanging widget tests on network font downloads.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  ServiceStats baseStats({
    Map<String, dynamic>? customMetrics,
    DateTime? lastReportedAt,
    int? instanceCount,
    double? errorRate,
    double? avgLatency,
    double? uptime,
  }) {
    return ServiceStats(
      serviceName: 'academicx',
      totalRequests: 42,
      errorRate: errorRate,
      avgLatency: avgLatency,
      uptime: uptime,
      errorCount: null,
      customMetrics: customMetrics,
      lastReportedAt: lastReportedAt,
      instanceCount: instanceCount,
    );
  }

  Future<void> pumpCard(WidgetTester tester, ServiceStats stats) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ServiceHealthCard(
            serviceName: 'academicx',
            stats: stats,
          ),
        ),
      ),
    );
    // Allow pulse AnimationController frames without waiting forever.
    await tester.pump();
  }

  group('ServiceHealthCard customMetrics chips', () {
    testWidgets('renders key:value chips when customMetrics is non-empty',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          customMetrics: {
            'students': 120,
            'activeToday': 45,
          },
        ),
      );

      expect(find.textContaining('students:'), findsOneWidget);
      expect(find.textContaining('120'), findsOneWidget);
      expect(find.textContaining('activeToday:'), findsOneWidget);
      expect(find.textContaining('45'), findsOneWidget);
    });

    testWidgets('renders nothing for chips when customMetrics is null',
        (tester) async {
      await pumpCard(tester, baseStats(customMetrics: null));

      expect(find.textContaining('students:'), findsNothing);
      expect(find.text('not reporting metrics yet'), findsOneWidget);
    });

    testWidgets('renders nothing for chips when customMetrics is empty',
        (tester) async {
      await pumpCard(tester, baseStats(customMetrics: {}));

      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('caps chips and shows overflow indicator', (tester) async {
      await pumpCard(
        tester,
        baseStats(
          customMetrics: {
            'a': 1,
            'b': 2,
            'c': 3,
            'd': 4,
            'e': 5,
            'f': 6,
          },
        ),
      );

      expect(find.textContaining('a:'), findsOneWidget);
      expect(find.textContaining('d:'), findsOneWidget);
      expect(find.textContaining('e:'), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('stringifies nested metric values without crashing',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          customMetrics: {
            'deep': {'x': 1},
            'list': [1, 2],
          },
        ),
      );

      expect(find.textContaining('deep:'), findsOneWidget);
      expect(find.textContaining('list:'), findsOneWidget);
    });

    testWidgets('shows compact relative lastReportedAt when present',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          lastReportedAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );

      expect(find.text('2m ago'), findsOneWidget);
    });
  });

  group('ServiceHealthCard instance badge (Phase 18)', () {
    testWidgets('shows badge when instanceCount > 1', (tester) async {
      await pumpCard(tester, baseStats(instanceCount: 3));

      expect(find.text('3 instances'), findsOneWidget);
    });

    testWidgets('hides badge when instanceCount is null', (tester) async {
      await pumpCard(tester, baseStats(instanceCount: null));

      expect(find.textContaining('instances'), findsNothing);
    });

    testWidgets('hides badge when instanceCount is 1', (tester) async {
      await pumpCard(tester, baseStats(instanceCount: 1));

      expect(find.textContaining('instances'), findsNothing);
    });
  });
}
