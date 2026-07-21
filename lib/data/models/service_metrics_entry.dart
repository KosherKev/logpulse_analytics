/// Lightweight DTO for one per-appId row from the provisional metrics summary
/// read route (`GET /api/v1/metrics/summary`).
///
/// Kept separate from [ServiceStats] so parsing and domain modeling stay
/// independent: the repository merges this into [ServiceStats], not the model
/// constructor.
///
/// Provisional contract (server may still change — only [parseServiceMetricsResponse]
/// should hardcode field names):
/// ```json
/// {
///   "data": [
///     {
///       "appId": "academicx",
///       "serviceName": "academicx",
///       "errorRate": 0.5,
///       "avgLatency": 42,
///       "uptime": 99.9,
///       "errorCount": 1,
///       "instanceCount": 3,
///       "lastReportedAt": "2026-07-21T12:00:00.000Z",
///       "metrics": { "students": 120, "activeToday": 45 }
///     }
///   ]
/// }
/// ```
/// Health (`kind: 'health'`) and custom metric (`kind: 'metric'`) documents are
/// expected to already be merged server-side into each entry.
class ServiceMetricsEntry {
  /// Collector app id — primary merge key against log-derived service names.
  final String appId;

  /// Optional display/alias name; falls back to [appId] when absent.
  final String? serviceName;

  final double? errorRate;
  final double? avgLatency;
  final double? uptime;
  final int? errorCount;

  /// Free-form custom metrics from `kind: 'metric'` docs. No fixed schema —
  /// unknown keys must pass through untouched.
  final Map<String, dynamic>? customMetrics;

  final DateTime? lastReportedAt;
  final int? instanceCount;

  const ServiceMetricsEntry({
    required this.appId,
    this.serviceName,
    this.errorRate,
    this.avgLatency,
    this.uptime,
    this.errorCount,
    this.customMetrics,
    this.lastReportedAt,
    this.instanceCount,
  });

  /// Resolved name for UI / merge map keys.
  String get resolvedName =>
      (serviceName != null && serviceName!.isNotEmpty) ? serviceName! : appId;
}
