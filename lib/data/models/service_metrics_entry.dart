/// Lightweight DTO for one per-appId row from
/// `GET /api/v1/metrics` (central-logging-service PR-24).
///
/// Kept separate from [ServiceStats] so parsing and domain modeling stay
/// independent: the repository merges this into [ServiceStats], not the model
/// constructor.
///
/// Real response shape (per entry):
/// ```json
/// {
///   "appId": "academicx",
///   "health": {
///     "status": "ok",
///     "instanceId": "rev-abc-xyz",
///     "uptimeSeconds": 86400,
///     "timestamp": "2026-07-21T12:00:00.000Z"
///   },
///   "metrics": { "students": 120, "activeToday": 45 },
///   "metricsReportedAt": "2026-07-21T12:01:00.000Z",
///   "instanceCount": 3,
///   "instances": [ { "instanceId", "lastSeen", "status?", "uptimeSeconds?" } ]
/// }
/// ```
/// `health` and `metrics` are independent — either may be null.
/// `instanceCount` is server-computed distinct IDs in the window; never derived
/// from `health.instanceId` alone.
class ServiceMetricsEntry {
  /// Collector app id — primary merge key against log-derived service names.
  final String appId;

  /// Optional display/alias name; falls back to [appId] when absent.
  final String? serviceName;

  /// Numeric request-health fields. PR-24 does not provide these; they remain
  /// null unless a future contract adds them. Kept for forward compatibility.
  final double? errorRate;
  final double? avgLatency;

  /// Percentage-typed uptime. PR-24 does **not** compute a percentage —
  /// this stays null. Do not alias [uptimeSeconds] into this field.
  final double? uptime;
  final int? errorCount;

  /// Free-form custom metrics from the top-level `metrics` object. No fixed
  /// schema — unknown keys must pass through untouched.
  final Map<String, dynamic>? customMetrics;

  /// Prefer `metricsReportedAt`; fall back to `health.timestamp` when only a
  /// health document exists.
  final DateTime? lastReportedAt;

  /// Distinct instance count from top-level `instanceCount` (CLS multi-instance).
  /// Null when omitted; badge hidden when null or ≤ 1. Never derived from
  /// `health.instanceId` alone.
  final int? instanceCount;

  /// Raw wire value of `health.status` (e.g. `"ok"`). Named distinctly from
  /// the derived [HealthStatus] enum / getter used for display.
  final String? reportedHealthStatus;

  /// Raw wire value of `health.uptimeSeconds`. Separate from percentage
  /// [uptime] so formatters never render seconds as `"up 86400.0%"`.
  final int? uptimeSeconds;

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
    this.reportedHealthStatus,
    this.uptimeSeconds,
  });

  /// Resolved name for UI / merge map keys.
  String get resolvedName =>
      (serviceName != null && serviceName!.isNotEmpty) ? serviceName! : appId;
}
