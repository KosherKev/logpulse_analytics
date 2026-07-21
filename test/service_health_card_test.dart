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
    String? reportedHealthStatus,
    int? uptimeSeconds,
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
      reportedHealthStatus: reportedHealthStatus,
      uptimeSeconds: uptimeSeconds,
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

      expect(find.textContaining('students:'), findsNothing);
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

  group('ServiceHealthCard three-state detail line (Phase 20)', () {
    testWidgets('middle state: reported health without numeric metrics',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          reportedHealthStatus: 'ok',
          uptimeSeconds: 3661, // 1h 1m
        ),
      );

      expect(find.text('not reporting metrics yet'), findsNothing);
      expect(find.textContaining('err '), findsNothing);
      expect(find.textContaining('ok'), findsOneWidget);
      expect(find.textContaining('up 1h 1m'), findsOneWidget);
    });

    testWidgets('full numeric state still renders when hasHealthMetrics',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          errorRate: 0.5,
          avgLatency: 42,
          uptime: 99.9,
        ),
      );

      expect(find.textContaining('err 0.5%'), findsOneWidget);
      expect(find.textContaining('42ms'), findsOneWidget);
      expect(find.text('not reporting metrics yet'), findsNothing);
    });

    testWidgets('numeric err/latency without uptime % still shows detail line',
        (tester) async {
      // CLS P1: byService supplies err + avgDuration, not uptime %.
      await pumpCard(
        tester,
        baseStats(
          errorRate: 1.5,
          avgLatency: 38,
        ),
      );

      expect(find.textContaining('err 1.5%'), findsOneWidget);
      expect(find.textContaining('38ms'), findsOneWidget);
      expect(find.textContaining('up '), findsNothing);
      expect(find.text('not reporting metrics yet'), findsNothing);
    });

    testWidgets('numerics + uptimeSeconds combine on detail line',
        (tester) async {
      await pumpCard(
        tester,
        baseStats(
          errorRate: 0.2,
          avgLatency: 12,
          uptimeSeconds: 3600,
        ),
      );

      expect(find.textContaining('err 0.2%'), findsOneWidget);
      expect(find.textContaining('up 1h'), findsOneWidget);
    });

    testWidgets('empty state when neither numerics nor reported health',
        (tester) async {
      await pumpCard(tester, baseStats());

      expect(find.text('not reporting metrics yet'), findsOneWidget);
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

    testWidgets('does not show badge from reported health alone (no count)',
        (tester) async {
      // PR-24 gives instanceId, not instanceCount — badge stays hidden.
      await pumpCard(
        tester,
        baseStats(
          reportedHealthStatus: 'ok',
          uptimeSeconds: 100,
          instanceCount: null,
        ),
      );

      expect(find.textContaining('instances'), findsNothing);
    });
  });
}
