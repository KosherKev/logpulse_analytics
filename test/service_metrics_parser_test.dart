import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseServiceMetricsResponse', () {
    test('(a) well-formed merged response maps all fields', () {
      final data = {
        'success': true,
        'data': [
          {
            'appId': 'academicx',
            'serviceName': 'academicx',
            'errorRate': 0.5,
            'avgLatency': 42,
            'uptime': 99.9,
            'errorCount': 1,
            'instanceCount': 3,
            'lastReportedAt': '2026-07-21T12:00:00.000Z',
            'metrics': {
              'students': 120,
              'activeToday': 45,
              'extraUnknown': {'nested': true},
            },
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);

      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.appId, 'academicx');
      expect(e.serviceName, 'academicx');
      expect(e.errorRate, 0.5);
      expect(e.avgLatency, 42);
      expect(e.uptime, 99.9);
      expect(e.errorCount, 1);
      expect(e.instanceCount, 3);
      expect(e.lastReportedAt, isNotNull);
      expect(e.lastReportedAt!.toUtc().toIso8601String(), '2026-07-21T12:00:00.000Z');
      expect(e.customMetrics, isNotNull);
      expect(e.customMetrics!['students'], 120);
      expect(e.customMetrics!['activeToday'], 45);
      // Unknown/extra fields pass through untouched.
      expect(e.customMetrics!['extraUnknown'], isA<Map>());
      expect((e.customMetrics!['extraUnknown'] as Map)['nested'], true);
    });

    test('(a) bare list response is accepted', () {
      final data = [
        {'appId': 'svc-a', 'uptime': 100.0},
      ];
      final entries = parseServiceMetricsResponse(data);
      expect(entries, hasLength(1));
      expect(entries.first.appId, 'svc-a');
      expect(entries.first.uptime, 100.0);
    });

    test('(b) empty / missing envelope returns empty list (404 path shape)', () {
      // When getServiceMetrics swallows a 404 it returns [] directly; the
      // parser must also tolerate empty payloads without throwing.
      expect(parseServiceMetricsResponse(null), isEmpty);
      expect(parseServiceMetricsResponse(<String, dynamic>{}), isEmpty);
      expect(parseServiceMetricsResponse({'data': null}), isEmpty);
      expect(parseServiceMetricsResponse({'data': <dynamic>[]}), isEmpty);
    });

    test('(c) malformed / partial entry still parses what is present', () {
      final data = {
        'data': [
          // Partial: health-ish fields only, no metrics map
          {
            'appId': 'partial-app',
            'uptime': '98.5', // string-encoded number
            // no errorRate, avgLatency, metrics
          },
          // Missing appId entirely — skipped
          {
            'uptime': 50.0,
            'metrics': {'x': 1},
          },
          // Non-map entry — skipped
          'not-a-map',
          // Metrics only (no health numbers)
          {
            'appId': 'metrics-only',
            'metrics': {'queueDepth': 7, 'deep': [1, 2, 3]},
          },
        ],
      };

      final entries = parseServiceMetricsResponse(data);

      expect(entries, hasLength(2));

      final partial = entries.firstWhere((e) => e.appId == 'partial-app');
      expect(partial.uptime, 98.5);
      expect(partial.errorRate, isNull);
      expect(partial.avgLatency, isNull);
      expect(partial.customMetrics, isNull);
      expect(partial.instanceCount, isNull);
      expect(partial.lastReportedAt, isNull);

      final metricsOnly = entries.firstWhere((e) => e.appId == 'metrics-only');
      expect(metricsOnly.customMetrics!['queueDepth'], 7);
      expect(metricsOnly.customMetrics!['deep'], [1, 2, 3]);
      expect(metricsOnly.uptime, isNull);
    });
  });
}
