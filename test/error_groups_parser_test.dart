import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/data/models/error_group.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseErrorGroupsResponse (CLS P2)', () {
    test('parses envelope with full group fields', () {
      final data = {
        'success': true,
        'data': [
          {
            'id': 'fp_a1b2c3',
            'message': 'Connection refused to redis',
            'errorCode': 'ECONNREFUSED',
            'count': 47,
            'services': ['academicx', 'payments-api'],
            'firstSeen': '2026-07-21T08:00:00.000Z',
            'lastSeen': '2026-07-21T12:30:00.000Z',
            'sampleStack': 'Error: ...',
            'sampleTraceId': 'trace-abc',
            'trend': 'increasing',
          },
        ],
      };

      final groups = parseErrorGroupsResponse(data);
      expect(groups, hasLength(1));
      final g = groups.first;
      expect(g.id, 'fp_a1b2c3');
      expect(g.message, 'Connection refused to redis');
      expect(g.errorCode, 'ECONNREFUSED');
      expect(g.count, 47);
      expect(g.services, ['academicx', 'payments-api']);
      expect(g.stackTrace, 'Error: ...');
      expect(g.sampleTraceId, 'trace-abc');
      expect(g.trend, TrendDirection.increasing);
      expect(g.severity, isNotNull);
    });

    test('empty data returns empty list', () {
      expect(parseErrorGroupsResponse({'success': true, 'data': []}), isEmpty);
      expect(parseErrorGroupsResponse(null), isEmpty);
    });

    test('trend mapping', () {
      List<ErrorGroup> one(String trend) => parseErrorGroupsResponse({
            'data': [
              {
                'id': 'x',
                'message': 'm',
                'count': 1,
                'services': [],
                'firstSeen': '2026-07-21T08:00:00.000Z',
                'lastSeen': '2026-07-21T12:00:00.000Z',
                'trend': trend,
              },
            ],
          });

      expect(one('decreasing').first.trend, TrendDirection.decreasing);
      expect(one('stable').first.trend, TrendDirection.stable);
      expect(one('unknown').first.trend, TrendDirection.stable);
    });
  });
}
