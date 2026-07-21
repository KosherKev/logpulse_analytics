import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/core/errors/exceptions.dart';
import 'package:logpulse_analytics/data/models/dashboard_stats.dart';
import 'package:logpulse_analytics/data/models/service_metrics_entry.dart';
import 'package:logpulse_analytics/data/repositories/dashboard_repository.dart';
import 'package:logpulse_analytics/data/services/api_service.dart';

/// Test double: overrides only the two methods [DashboardRepository.getStats]
/// exercises, without hitting the network.
class _FakeApiService extends ApiService {
  _FakeApiService({
    required this.dashboardStatsResult,
    required this.serviceMetricsResult,
  });

  /// Completer-style handlers so callers can control success vs throw.
  final Future<DashboardStats> Function() dashboardStatsResult;
  final Future<List<ServiceMetricsEntry>> Function() serviceMetricsResult;

  var dashboardStatsCalls = 0;
  var serviceMetricsCalls = 0;

  /// True once both methods have been entered (concurrency check).
  bool bothStarted = false;
  bool _statsStarted = false;
  bool _metricsStarted = false;

  void _markStarted({required bool stats}) {
    if (stats) {
      _statsStarted = true;
    } else {
      _metricsStarted = true;
    }
    if (_statsStarted && _metricsStarted) {
      bothStarted = true;
    }
  }

  @override
  Future<DashboardStats> getDashboardStats({String? timeRange}) async {
    dashboardStatsCalls++;
    _markStarted(stats: true);
    return dashboardStatsResult();
  }

  @override
  Future<List<ServiceMetricsEntry>> getServiceMetrics({String? appId}) async {
    serviceMetricsCalls++;
    _markStarted(stats: false);
    return serviceMetricsResult();
  }
}

DashboardStats _sampleLogStats() {
  return DashboardStats(
    totalLogs: 100,
    errorRate: 2.5,
    avgLatency: 40,
    requestsPerHour: 100,
    serviceStats: {
      'academicx': ServiceStats(
        serviceName: 'academicx',
        totalRequests: 80,
        errorRate: null,
        avgLatency: null,
        uptime: null,
        errorCount: null,
      ),
      'other-svc': ServiceStats(
        serviceName: 'other-svc',
        totalRequests: 20,
        errorRate: null,
        avgLatency: null,
        uptime: null,
        errorCount: null,
      ),
    },
    errorsByLevel: {'error': 5},
    requestsByStatus: {'200': 95},
  );
}

List<ServiceMetricsEntry> _sampleMetrics() {
  return [
    ServiceMetricsEntry(
      appId: 'academicx',
      reportedHealthStatus: 'ok',
      uptimeSeconds: 3600,
      customMetrics: {'students': 12},
      lastReportedAt: DateTime.utc(2026, 7, 21, 12),
    ),
  ];
}

void main() {
  group('DashboardRepository.getStats — metrics isolation (Phase 21)', () {
    test(
      'metrics non-404 AppException → getStats still succeeds with log data only',
      () async {
        final api = _FakeApiService(
          dashboardStatsResult: () async => _sampleLogStats(),
          serviceMetricsResult: () async {
            throw ApiException('HTTP 500: boom', statusCode: 500);
          },
        );
        final repo = DashboardRepository(api);

        final result = await repo.getStats(timeRange: 'last_24h');

        expect(result.totalLogs, 100);
        expect(result.errorRate, 2.5);
        expect(result.avgLatency, 40);
        expect(result.errorsByLevel, {'error': 5});
        // Merge with empty metrics: serviceStats unchanged from log-derived.
        expect(result.serviceStats, isNotNull);
        expect(result.serviceStats!.keys, containsAll(['academicx', 'other-svc']));
        expect(result.serviceStats!['academicx']!.totalRequests, 80);
        expect(result.serviceStats!['academicx']!.reportedHealthStatus, isNull);
        expect(result.serviceStats!['academicx']!.customMetrics, isNull);
        expect(result.serviceStats!['academicx']!.uptimeSeconds, isNull);
        expect(api.bothStarted, isTrue);
      },
    );

    test(
      'metrics non-DioException (generic/parse) → same soft-fail outcome',
      () async {
        final api = _FakeApiService(
          dashboardStatsResult: () async => _sampleLogStats(),
          serviceMetricsResult: () async {
            // Simulate a parse-time crash that is not a DioException /
            // AppException — must still be caught at the repository layer.
            throw const FormatException('unexpected metrics payload');
          },
        );
        final repo = DashboardRepository(api);

        final result = await repo.getStats();

        expect(result.totalLogs, 100);
        expect(result.serviceStats!['academicx']!.reportedHealthStatus, isNull);
        expect(result.serviceStats!['academicx']!.hasReportedHealth, isFalse);
      },
    );

    test(
      'log-stats failure still fails getStats (must not regress)',
      () async {
        final api = _FakeApiService(
          dashboardStatsResult: () async {
            throw ApiException('HTTP 500: stats down', statusCode: 500);
          },
          serviceMetricsResult: () async => _sampleMetrics(),
        );
        final repo = DashboardRepository(api);

        await expectLater(
          repo.getStats(),
          throwsA(isA<AppException>()),
        );
      },
    );

    test(
      'both succeed → metrics merge into matching serviceStats (Phase 20 regression)',
      () async {
        final api = _FakeApiService(
          dashboardStatsResult: () async => _sampleLogStats(),
          serviceMetricsResult: () async => _sampleMetrics(),
        );
        final repo = DashboardRepository(api);

        final result = await repo.getStats(timeRange: 'last_24h');

        expect(result.totalLogs, 100);
        // requestsPerHour for last_24h: 100/24 rounded
        expect(result.requestsPerHour, (100 / 24).round());

        final academicx = result.serviceStats!['academicx']!;
        expect(academicx.totalRequests, 80); // log-derived count kept
        expect(academicx.reportedHealthStatus, 'ok');
        expect(academicx.uptimeSeconds, 3600);
        expect(academicx.customMetrics!['students'], 12);
        expect(academicx.hasReportedHealth, isTrue);

        // Unmatched log service stays without metrics fields.
        final other = result.serviceStats!['other-svc']!;
        expect(other.totalRequests, 20);
        expect(other.reportedHealthStatus, isNull);
        expect(other.customMetrics, isNull);

        expect(api.bothStarted, isTrue);
        expect(api.dashboardStatsCalls, 1);
        expect(api.serviceMetricsCalls, 1);
      },
    );

    test(
      'metrics-only app (no logs) still surfaces when metrics succeed',
      () async {
        final api = _FakeApiService(
          dashboardStatsResult: () async => DashboardStats(
            totalLogs: 0,
            errorRate: 0,
            avgLatency: 0,
            requestsPerHour: 0,
            serviceStats: {},
          ),
          serviceMetricsResult: () async => [
            const ServiceMetricsEntry(
              appId: 'telemetry-only',
              reportedHealthStatus: 'ok',
              uptimeSeconds: 10,
            ),
          ],
        );
        final repo = DashboardRepository(api);

        final result = await repo.getStats();

        expect(result.serviceStats!.containsKey('telemetry-only'), isTrue);
        expect(result.serviceStats!['telemetry-only']!.totalRequests, 0);
        expect(
          result.serviceStats!['telemetry-only']!.reportedHealthStatus,
          'ok',
        );
      },
    );
  });
}
