import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/core/errors/exceptions.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

void main() {
  group('parseLogsPageResponse (CLS P1 envelope)', () {
    Map<String, dynamic> sampleLog({String id = '1'}) => {
          'id': id,
          'timestamp': '2026-07-21T12:00:00.000Z',
          'level': 'info',
          'service': 'academicx',
          'method': 'GET',
          'path': '/v1/x',
          'statusCode': 200,
          'duration': 12,
        };

    test('envelope with total and pagination', () {
      final data = {
        'success': true,
        'data': [sampleLog(id: 'a'), sampleLog(id: 'b')],
        'total': 4821,
        'meta': {'limit': 20, 'skip': 0},
        'pagination': {
          'total': 4821,
          'limit': 20,
          'skip': 0,
          'hasMore': true,
        },
      };

      final page = parseLogsPageResponse(data);
      expect(page.logs, hasLength(2));
      expect(page.logs.first.id, 'a');
      expect(page.total, 4821);
      expect(page.hasMore, isTrue);
    });

    test('total from top-level preferred; hasMore from pagination', () {
      final data = {
        'data': [sampleLog()],
        'total': 100,
        'pagination': {'total': 99, 'hasMore': false},
      };
      final page = parseLogsPageResponse(data);
      expect(page.total, 100);
      expect(page.hasMore, isFalse);
    });

    test('bare list legacy — no total', () {
      final data = [sampleLog(id: 'x')];
      final page = parseLogsPageResponse(data);
      expect(page.logs, hasLength(1));
      expect(page.total, isNull);
      expect(page.hasMore, isNull);
    });

    test('_id mapped to id', () {
      final data = {
        'data': [
          {
            '_id': 'mongo-id',
            'timestamp': '2026-07-21T12:00:00.000Z',
            'level': 'error',
            'service': 'svc',
          },
        ],
        'total': 1,
      };
      final page = parseLogsPageResponse(data);
      expect(page.logs.first.id, 'mongo-id');
    });

    test('invalid envelope throws', () {
      expect(
        () => parseLogsPageResponse({'data': null}),
        throwsA(isA<ParseException>()),
      );
    });
  });
}
