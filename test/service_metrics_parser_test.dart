import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseServiceMetricsResponse (PR-24 shape)', () {
    test('both health and metrics present', () {
      final data = {
        'success': true,
        'data': [
          {
            'appId': 'academicx',
            'health': {
              'status': 'ok',
              'instanceId': 'rev-abc-1',
              'uptimeSeconds': 86400,
              'timestamp': '2026-07-21T11:00:00.000Z',
            },
            'metrics': {
              'students': 120,
              'activeToday': 45,
              'extraUnknown': {'nested': true},
            },
            'metricsReportedAt': '2026-07-21T12:00:00.000Z',
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);

      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.appId, 'academicx');
      expect(e.reportedHealthStatus, 'ok');
      expect(e.uptimeSeconds, 86400);
      // Prefer metricsReportedAt over health.timestamp.
      expect(
        e.lastReportedAt!.toUtc().toIso8601String(),
        '2026-07-21T12:00:00.000Z',
      );
      expect(e.customMetrics!['students'], 120);
      expect(e.customMetrics!['activeToday'], 45);
      expect(e.customMetrics!['extraUnknown'], isA<Map>());
      // Percentage uptime / errorRate never filled from PR-24.
      expect(e.uptime, isNull);
      expect(e.errorRate, isNull);
      expect(e.avgLatency, isNull);
      // Single instanceId must not become instanceCount.
      expect(e.instanceCount, isNull);
    });

    test('health-only fixture (metrics null)', () {
      final data = {
        'data': [
          {
            'appId': 'health-only',
            'health': {
              'status': 'ok',
              'instanceId': 'i-1',
              'uptimeSeconds': 125,
              'timestamp': '2026-07-21T10:00:00.000Z',
            },
            'metrics': null,
            'metricsReportedAt': null,
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.reportedHealthStatus, 'ok');
      expect(e.uptimeSeconds, 125);
      expect(e.customMetrics, isNull);
      // Fall back to health.timestamp when metricsReportedAt is absent.
      expect(
        e.lastReportedAt!.toUtc().toIso8601String(),
        '2026-07-21T10:00:00.000Z',
      );
    });

    test('metrics-only fixture (health null)', () {
      final data = {
        'data': [
          {
            'appId': 'metrics-only',
            'health': null,
            'metrics': {'queueDepth': 7, 'deep': [1, 2, 3]},
            'metricsReportedAt': '2026-07-21T09:00:00.000Z',
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.reportedHealthStatus, isNull);
      expect(e.uptimeSeconds, isNull);
      expect(e.customMetrics!['queueDepth'], 7);
      expect(e.customMetrics!['deep'], [1, 2, 3]);
      expect(
        e.lastReportedAt!.toUtc().toIso8601String(),
        '2026-07-21T09:00:00.000Z',
      );
    });

    test('neither health nor metrics present', () {
      final data = {
        'data': [
          {
            'appId': 'empty-app',
            'health': null,
            'metrics': null,
            'metricsReportedAt': null,
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.appId, 'empty-app');
      expect(e.reportedHealthStatus, isNull);
      expect(e.uptimeSeconds, isNull);
      expect(e.customMetrics, isNull);
      expect(e.lastReportedAt, isNull);
    });

    test('bare list response is accepted', () {
      final data = [
        {
          'appId': 'svc-a',
          'health': {'status': 'ok', 'uptimeSeconds': 10},
          'metrics': null,
        },
      ];
      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      expect(entries.first.appId, 'svc-a');
      expect(entries.first.reportedHealthStatus, 'ok');
      expect(entries.first.uptimeSeconds, 10);
    });

    test('empty / missing envelope returns empty list', () {
      expect(parseServiceMetricsResponse(null), isEmpty);
      expect(parseServiceMetricsResponse(<String, dynamic>{}), isEmpty);
      expect(parseServiceMetricsResponse({'data': null}), isEmpty);
      expect(parseServiceMetricsResponse({'data': <dynamic>[]}), isEmpty);
    });

    test('malformed / partial entries still parse what is present', () {
      final data = {
        'data': [
          // health.status wrong type — leave reportedHealthStatus null
          {
            'appId': 'bad-status',
            'health': {
              'status': 123,
              'uptimeSeconds': '98', // string-encoded ok via readInt
            },
          },
          // Missing appId — skipped
          {
            'health': {'status': 'ok'},
            'metrics': {'x': 1},
          },
          // Non-map entry — skipped
          'not-a-map',
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final bad = entries.first;
      expect(bad.appId, 'bad-status');
      expect(bad.reportedHealthStatus, isNull);
      expect(bad.uptimeSeconds, 98);
    });
  });

  group('ServiceStats health derivation (Phase 20)', () {
    test('hasReportedHealth true when status string present', () {
      final s = ServiceStats(
        serviceName: 'a',
        totalRequests: 0,
        errorRate: null,
        avgLatency: null,
        uptime: null,
        errorCount: null,
        reportedHealthStatus: 'ok',
        uptimeSeconds: 3600,
      );
      expect(s.hasReportedHealth, isTrue);
      expect(s.hasHealthMetrics, isFalse);
      expect(s.healthStatus, HealthStatus.healthy);
      expect(s.formattedUptimeDuration, '1h');
    });

    test('unknown reported status maps to degraded', () {
      final s = ServiceStats(
        serviceName: 'a',
        totalRequests: 0,
        errorRate: null,
        avgLatency: null,
        uptime: null,
        errorCount: null,
        reportedHealthStatus: 'weird',
      );
      expect(s.healthStatus, HealthStatus.degraded);
    });

    test('no reported health and no numerics → unknown', () {
      final s = ServiceStats(
        serviceName: 'a',
        totalRequests: 5,
        errorRate: null,
        avgLatency: null,
        uptime: null,
        errorCount: null,
      );
      expect(s.hasReportedHealth, isFalse);
      expect(s.healthStatus, HealthStatus.unknown);
    });

    test('numeric metrics still take priority over reported status', () {
      final s = ServiceStats(
        serviceName: 'a',
        totalRequests: 5,
        errorRate: 6.0,
        avgLatency: 10,
        uptime: 99.0,
        errorCount: 1,
        reportedHealthStatus: 'ok',
      );
      expect(s.hasHealthMetrics, isTrue);
      expect(s.healthStatus, HealthStatus.unhealthy);
    });
  });
}
