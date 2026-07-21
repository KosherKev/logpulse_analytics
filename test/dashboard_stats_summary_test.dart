import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';

void main() {
  group('DashboardStats.fromApiJson — CLS P1 byService objects', () {
    test('object byService maps errorRate, avgDuration, errorCount', () {
      final json = {
        'success': true,
        'data': {
          'totalLogs': 1520,
          'errorRate': '2.50',
          'avgDuration': 42,
          'byLevel': {'info': 1200, 'error': 40},
          'byStatusCode': {'200': 1400, '500': 40},
          'byService': {
            'academicx': {
              'totalRequests': 800,
              'errorCount': 12,
              'errorRate': 1.5,
              'avgDuration': 38,
            },
            'payments-api': {
              'totalRequests': 720,
              'errorCount': 28,
              'errorRate': 3.9,
              'avgDuration': 51,
            },
          },
        },
      };

      final stats = DashboardStats.fromApiJson(json);

      expect(stats.totalLogs, 1520);
      expect(stats.errorRate, 2.5);
      expect(stats.avgLatency, 42);

      final ax = stats.serviceStats!['academicx']!;
      expect(ax.totalRequests, 800);
      expect(ax.errorCount, 12);
      expect(ax.errorRate, 1.5);
      expect(ax.avgLatency, 38);
      expect(ax.uptime, isNull);
      expect(ax.hasHealthMetrics, isTrue);
      expect(ax.healthStatus, HealthStatus.degraded); // 1.5% → degraded (<5)

      final pay = stats.serviceStats!['payments-api']!;
      expect(pay.errorRate, 3.9);
      expect(pay.avgLatency, 51);
      expect(pay.healthStatus, HealthStatus.degraded);
    });

    test('bare-int byService still accepted (legacy counts only)', () {
      final json = {
        'data': {
          'totalLogs': 10,
          'errorRate': 0,
          'avgDuration': 0,
          'byService': {'legacy-svc': 10},
        },
      };

      final stats = DashboardStats.fromApiJson(json);
      final s = stats.serviceStats!['legacy-svc']!;
      expect(s.totalRequests, 10);
      expect(s.errorRate, isNull);
      expect(s.avgLatency, isNull);
      expect(s.hasHealthMetrics, isFalse);
      expect(s.healthStatus, HealthStatus.unknown);
    });

    test('errorRate under 1% → healthy', () {
      final json = {
        'data': {
          'totalLogs': 100,
          'errorRate': 0.1,
          'avgDuration': 10,
          'byService': {
            'ok-svc': {
              'totalRequests': 100,
              'errorCount': 0,
              'errorRate': 0.2,
              'avgDuration': 12,
            },
          },
        },
      };
      final s = DashboardStats.fromApiJson(json).serviceStats!['ok-svc']!;
      expect(s.healthStatus, HealthStatus.healthy);
    });

    test('errorRate >= 5% → unhealthy', () {
      final json = {
        'data': {
          'totalLogs': 100,
          'errorRate': 10,
          'avgDuration': 10,
          'byService': {
            'bad-svc': {
              'totalRequests': 100,
              'errorCount': 10,
              'errorRate': 10.0,
              'avgDuration': 200,
            },
          },
        },
      };
      final s = DashboardStats.fromApiJson(json).serviceStats!['bad-svc']!;
      expect(s.healthStatus, HealthStatus.unhealthy);
    });
  });
}
