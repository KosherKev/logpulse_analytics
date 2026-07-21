import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseServiceMetricsResponse (PR-24 + multi-instance)', () {
    test('both health and metrics present + instanceCount', () {
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
            'instanceCount': 3,
            'instances': [
              {
                'instanceId': 'rev-abc-1',
                'lastSeen': '2026-07-21T12:00:00.000Z',
                'status': 'ok',
                'uptimeSeconds': 86400,
              },
              {
                'instanceId': 'rev-def-2',
                'lastSeen': '2026-07-21T11:58:00.000Z',
                'status': 'ok',
              },
              {
                'instanceId': 'rev-ghi-3',
                'lastSeen': '2026-07-21T11:55:00.000Z',
                'status': 'degraded',
              },
            ],
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);

      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.appId, 'academicx');
      expect(e.reportedHealthStatus, 'ok');
      expect(e.uptimeSeconds, 86400);
      expect(
        e.lastReportedAt!.toUtc().toIso8601String(),
        '2026-07-21T12:00:00.000Z',
      );
      expect(e.customMetrics!['students'], 120);
      expect(e.customMetrics!['activeToday'], 45);
      expect(e.customMetrics!['extraUnknown'], isA<Map>());
      expect(e.uptime, isNull);
      expect(e.errorRate, isNull);
      expect(e.avgLatency, isNull);
      // Top-level server count, not derived from health.instanceId.
      expect(e.instanceCount, 3);
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
            'instanceCount': 1,
            'instances': [
              {
                'instanceId': 'i-1',
                'lastSeen': '2026-07-21T10:00:00.000Z',
                'status': 'ok',
                'uptimeSeconds': 125,
              },
            ],
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.reportedHealthStatus, 'ok');
      expect(e.uptimeSeconds, 125);
      expect(e.customMetrics, isNull);
      expect(e.instanceCount, 1);
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
            'metrics': {
              'queueDepth': 7,
              'deep': [1, 2, 3]
            },
            'metricsReportedAt': '2026-07-21T09:00:00.000Z',
            'instanceCount': 0,
            'instances': <dynamic>[],
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.reportedHealthStatus, isNull);
      expect(e.uptimeSeconds, isNull);
      expect(e.customMetrics!['queueDepth'], 7);
      expect(e.instanceCount, 0);
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
            'instanceCount': 0,
            'instances': <dynamic>[],
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
      expect(e.instanceCount, 0);
    });

    test('health.instanceId alone does not invent instanceCount', () {
      final data = {
        'data': [
          {
            'appId': 'solo',
            'health': {
              'status': 'ok',
              'instanceId': 'only-one',
              'uptimeSeconds': 10,
              'timestamp': '2026-07-21T10:00:00.000Z',
            },
            // No top-level instanceCount — must stay null (not 1).
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);
      expect(entries.first.instanceCount, isNull);
      expect(entries.first.reportedHealthStatus, 'ok');
    });

    test('bare list response is accepted', () {
      final data = [
        {
          'appId': 'svc-a',
          'health': {'status': 'ok', 'uptimeSeconds': 10},
          'metrics': null,
          'instanceCount': 2,
        },
      ];
      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      expect(entries.first.appId, 'svc-a');
      expect(entries.first.reportedHealthStatus, 'ok');
      expect(entries.first.uptimeSeconds, 10);
      expect(entries.first.instanceCount, 2);
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
          {
            'appId': 'bad-status',
            'health': {
              'status': 123,
              'uptimeSeconds': '98',
            },
          },
          {
            'health': {'status': 'ok'},
            'metrics': {'x': 1},
          },
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

  group('ServiceStats health derivation (full vocabulary)', () {
    ServiceStats withStatus(String? status) => ServiceStats(
          serviceName: 'a',
          totalRequests: 0,
          errorRate: null,
          avgLatency: null,
          uptime: null,
          errorCount: null,
          reportedHealthStatus: status,
          uptimeSeconds: 3600,
        );

    test('ok → healthy', () {
      expect(withStatus('ok').healthStatus, HealthStatus.healthy);
      expect(withStatus('ok').hasReportedHealth, isTrue);
      expect(withStatus('ok').formattedUptimeDuration, '1h');
    });

    test('error → unhealthy', () {
      expect(withStatus('error').healthStatus, HealthStatus.unhealthy);
    });

    test('degraded / starting / stopping → degraded', () {
      expect(withStatus('degraded').healthStatus, HealthStatus.degraded);
      expect(withStatus('starting').healthStatus, HealthStatus.degraded);
      expect(withStatus('stopping').healthStatus, HealthStatus.degraded);
    });

    test('unknown non-empty status → degraded', () {
      expect(withStatus('weird').healthStatus, HealthStatus.degraded);
    });

    test('no reported health and no numerics → unknown', () {
      final s = withStatus(null);
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

  group('parseTimeSeriesResponse (CLS P0 shape)', () {
    test('envelope with meta maps long field names', () {
      final data = {
        'success': true,
        'data': [
          {
            'timestamp': '2026-07-21T00:00:00.000Z',
            'totalCount': 120,
            'errorCount': 4,
          },
          {
            'timestamp': '2026-07-21T01:00:00.000Z',
            'totalCount': 98,
            'errorCount': 1,
          },
        ],
        'meta': {
          'bucketMs': 3600000,
          'timeRange': 'last_24h',
          'from': '2026-07-20T01:00:00.000Z',
          'to': '2026-07-21T01:00:00.000Z',
        },
      };

      final points = parseTimeSeriesResponse(data);
      expect(points, hasLength(2));
      expect(points[0].timestamp.toUtc().toIso8601String(),
          '2026-07-21T00:00:00.000Z');
      expect(points[0].totalCount, 120);
      expect(points[0].errorCount, 4);
      expect(points[1].totalCount, 98);
      expect(points[1].errorCount, 1);
      // No zero-fill: sparse buckets are fine.
    });

    test('bare list and total/errors aliases', () {
      final data = [
        {
          'timestamp': '2026-07-21T00:00:00.000Z',
          'total': 10,
          'errors': 2,
        },
      ];
      final points = parseTimeSeriesResponse(data);
      expect(points, hasLength(1));
      expect(points.first.totalCount, 10);
      expect(points.first.errorCount, 2);
    });

    test('invalid envelope throws ParseException', () {
      expect(
        () => parseTimeSeriesResponse({'data': null}),
        throwsA(isA<Exception>()),
      );
    });
  });
}
