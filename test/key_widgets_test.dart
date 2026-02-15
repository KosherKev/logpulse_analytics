import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:logpulse_analytics/data/models/dashboard_stats.dart';
import 'package:logpulse_analytics/data/models/log_entry.dart';
import 'package:logpulse_analytics/presentation/widgets/dashboard/error_rate_chart.dart';
import 'package:logpulse_analytics/presentation/widgets/dashboard/stats_grid.dart';
import 'package:logpulse_analytics/presentation/widgets/logs/enhanced_log_card.dart';

void main() {
  group('EnhancedLogCard', () {
    testWidgets('renders core log information and responds to tap',
        (WidgetTester tester) async {
      var tapped = false;

      final log = LogEntry(
        id: '1',
        timestamp: DateTime.now(),
        level: 'error',
        service: 'api-service',
        traceId: 'trace-123',
        method: 'GET',
        path: '/v1/resource',
        statusCode: 500,
        duration: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedLogCard(
              log: log,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('api-service'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('GET'), findsOneWidget);
      expect(find.text('/v1/resource'), findsOneWidget);

      await tester.tap(find.byType(EnhancedLogCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('StatsGrid', () {
    testWidgets('displays dashboard stat values',
        (WidgetTester tester) async {
      final stats = DashboardStats(
        totalLogs: 1000,
        errorRate: 2.5,
        avgLatency: 150,
        requestsPerHour: 300,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsGrid(stats: stats),
          ),
        ),
      );

      expect(find.text('Total Logs'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);

      expect(find.text('Error Rate'), findsOneWidget);
      expect(find.text(stats.formattedErrorRate), findsOneWidget);

      expect(find.text('Avg Latency'), findsOneWidget);
      expect(find.text(stats.formattedAvgLatency), findsOneWidget);

      expect(find.text('Requests/Hour'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
    });
  });

  group('ErrorRateChart', () {
    testWidgets('shows empty state when there is no data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(points: []),
          ),
        ),
      );

      expect(find.text('No chart data available'), findsOneWidget);
    });

    testWidgets('renders a LineChart when points are provided',
        (WidgetTester tester) async {
      final points = <FlSpot>[
        const FlSpot(0, 0),
        const FlSpot(1, 1),
        const FlSpot(2, 0.5),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(points: points),
          ),
        ),
      );

      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}

