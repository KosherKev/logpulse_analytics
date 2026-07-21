import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseServicesListResponse (CLS P2)', () {
    test('parses catalog rows', () {
      final data = {
        'success': true,
        'data': [
          {
            'name': 'academicx',
            'displayName': 'AcademicX',
            'totalRequests': 800,
            'errorRate': 1.5,
            'avgLatency': 38,
            'lastSeen': '2026-07-21T12:01:00.000Z',
            'instanceCount': 3,
          },
        ],
      };

      final list = parseServicesListResponse(data);
      expect(list, hasLength(1));
      final s = list.first;
      expect(s.name, 'academicx');
      expect(s.label, 'AcademicX');
      expect(s.totalRequests, 800);
      expect(s.errorRate, 1.5);
      expect(s.avgLatency, 38);
      expect(s.instanceCount, 3);
      expect(s.lastSeen, isNotNull);
    });

    test('empty list', () {
      expect(parseServicesListResponse({'data': []}), isEmpty);
    });
  });

  group('parseServiceDetailResponse (CLS P2)', () {
    test('parses endpoints, health, metrics, instances', () {
      final data = {
        'success': true,
        'data': {
          'name': 'academicx',
          'totalRequests': 800,
          'errorRate': 1.5,
          'avgLatency': 38,
          'instanceCount': 2,
          'endpoints': [
            {
              'path': '/v1/students',
              'method': 'GET',
              'requestCount': 400,
              'errorRate': 0.5,
              'avgLatency': 30,
              'errorCount': 2,
            },
          ],
          'health': {
            'status': 'ok',
            'instanceId': 'rev-abc',
            'uptimeSeconds': 86400,
            'timestamp': '2026-07-21T12:00:00.000Z',
          },
          'metrics': {'students': 120},
          'instances': [
            {
              'instanceId': 'rev-abc',
              'lastSeen': '2026-07-21T12:00:00.000Z',
              'status': 'ok',
              'uptimeSeconds': 86400,
            },
          ],
        },
      };

      final d = parseServiceDetailResponse(data);
      expect(d.summary.name, 'academicx');
      expect(d.endpoints, hasLength(1));
      expect(d.endpoints.first.formattedEndpoint, 'GET /v1/students');
      expect(d.healthStatus, 'ok');
      expect(d.uptimeSeconds, 86400);
      expect(d.metrics!['students'], 120);
      expect(d.instances, hasLength(1));
      expect(d.instances.first.instanceId, 'rev-abc');
    });
  });
}
