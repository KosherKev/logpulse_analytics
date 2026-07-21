import '../models/dashboard_stats.dart';
import '../models/service_metrics_entry.dart';
import '../models/time_series_point.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

/// Repository for dashboard operations
class DashboardRepository {
  final ApiService _apiService;
  
  DashboardRepository(this._apiService);
  
  /// Fetch dashboard statistics, merging log-derived request counts with
  /// optional per-service metrics from `GET /api/v1/metrics` (PR-24).
  ///
  /// Both sources are fetched concurrently. Metrics soft-fail (empty list on
  /// 404 inside [ApiService.getServiceMetrics]); log stats remain the source
  /// of truth for request counts when metrics are absent.
  Future<DashboardStats> getStats({String? timeRange}) async {
    try {
      final results = await Future.wait<Object>([
        _apiService.getDashboardStats(timeRange: timeRange),
        // Metrics is latest-snapshot only — no timeRange on the PR-24 route.
        _apiService.getServiceMetrics(),
      ]);
      final stats = results[0] as DashboardStats;
      final metrics = results[1] as List<ServiceMetricsEntry>;

      final range = timeRange ?? 'last_24h';
      final hours = _hoursForRange(range);
      final reqPerHour =
          hours > 0 ? (stats.totalLogs / hours).round() : stats.totalLogs;

      return DashboardStats(
        totalLogs: stats.totalLogs,
        errorRate: stats.errorRate,
        avgLatency: stats.avgLatency,
        requestsPerHour: reqPerHour,
        serviceStats: _mergeServiceMetrics(stats.serviceStats, metrics),
        errorsByLevel: stats.errorsByLevel,
        requestsByStatus: stats.requestsByStatus,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }

  /// Merge log-derived [ServiceStats] (real request counts, null health) with
  /// metrics entries keyed by appId / serviceName.
  ///
  /// - Log-only service → unchanged (null health, "not reporting").
  /// - Metrics-only app (telemetry with zero logs) → new entry, totalRequests: 0.
  /// - Both → health/custom fields filled from metrics, counts kept from logs.
  Map<String, ServiceStats>? _mergeServiceMetrics(
    Map<String, ServiceStats>? logDerived,
    List<ServiceMetricsEntry> metrics,
  ) {
    if ((logDerived == null || logDerived.isEmpty) && metrics.isEmpty) {
      return logDerived;
    }

    final merged = <String, ServiceStats>{
      if (logDerived != null) ...logDerived,
    };

    // Index existing keys lowercased for tolerant matching (appId vs service name).
    String? findExistingKey(String appId, String? serviceName) {
      if (merged.containsKey(appId)) return appId;
      if (serviceName != null && merged.containsKey(serviceName)) {
        return serviceName;
      }
      final appLower = appId.toLowerCase();
      final serviceLower = serviceName?.toLowerCase();
      for (final key in merged.keys) {
        final k = key.toLowerCase();
        if (k == appLower || (serviceLower != null && k == serviceLower)) {
          return key;
        }
      }
      return null;
    }

    for (final entry in metrics) {
      final existingKey = findExistingKey(entry.appId, entry.serviceName);
      if (existingKey != null) {
        final existing = merged[existingKey]!;
        merged[existingKey] = ServiceStats(
          serviceName: existing.serviceName,
          totalRequests: existing.totalRequests,
          errorRate: entry.errorRate ?? existing.errorRate,
          avgLatency: entry.avgLatency ?? existing.avgLatency,
          uptime: entry.uptime ?? existing.uptime,
          errorCount: entry.errorCount ?? existing.errorCount,
          customMetrics: entry.customMetrics ?? existing.customMetrics,
          lastReportedAt: entry.lastReportedAt ?? existing.lastReportedAt,
          instanceCount: entry.instanceCount ?? existing.instanceCount,
          reportedHealthStatus:
              entry.reportedHealthStatus ?? existing.reportedHealthStatus,
          uptimeSeconds: entry.uptimeSeconds ?? existing.uptimeSeconds,
        );
      } else {
        // Telemetry-only: app reports metrics but has produced zero logs.
        final name = entry.resolvedName;
        merged[name] = ServiceStats(
          serviceName: name,
          totalRequests: 0,
          errorRate: entry.errorRate,
          avgLatency: entry.avgLatency,
          uptime: entry.uptime,
          errorCount: entry.errorCount,
          customMetrics: entry.customMetrics,
          lastReportedAt: entry.lastReportedAt,
          instanceCount: entry.instanceCount,
          reportedHealthStatus: entry.reportedHealthStatus,
          uptimeSeconds: entry.uptimeSeconds,
        );
      }
    }

    return merged;
  }
  
  /// Check service health
  Future<bool> checkHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      return false;
    }
  }

  /// Fetch time-series data using dedicated endpoint with fallback
  Future<List<TimeSeriesPoint>> getErrorTrafficSeries({String? timeRange}) async {
    try {
      return await _apiService.getTimeSeries(timeRange: timeRange);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch time-series data: ${e.toString()}');
    }
  }

  int _hoursForRange(String timeRange) {
    switch (timeRange) {
      case 'last_hour':
        return 1;
      case 'last_7d':
        return 7 * 24;
      case 'last_30d':
        return 30 * 24;
      case 'last_24h':
      default:
        return 24;
    }
  }

}
