import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

/// Dashboard statistics model
@JsonSerializable()
class DashboardStats {
  final int totalLogs;
  final double errorRate;
  final double avgLatency;
  final int requestsPerHour;
  final Map<String, ServiceStats>? serviceStats;
  final Map<String, int>? errorsByLevel;
  final Map<String, int>? requestsByStatus;
  
  DashboardStats({
    required this.totalLogs,
    required this.errorRate,
    required this.avgLatency,
    required this.requestsPerHour,
    this.serviceStats,
    this.errorsByLevel,
    this.requestsByStatus,
  });
  
  factory DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);

  /// Create dashboard stats from the central logging API summary response
  /// shape:
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "totalLogs": 23,
  ///     "errorRate": "0.00",
  ///     "avgDuration": 0,
  ///     "byLevel": {"info": 12, "warn": 11},
  ///     "byService": {"central-logging-service": 23},
  ///     "byStatusCode": {"null": 23}
  ///   }
  /// }
  factory DashboardStats.fromApiJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    int readInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double readDouble(dynamic value, {double fallback = 0.0}) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    final totalLogs = readInt(root['totalLogs']);
    final errorRate = readDouble(root['errorRate']);
    final avgLatency = readDouble(root['avgDuration']);

    final byLevel = root['byLevel'];
    Map<String, int>? errorsByLevel;
    if (byLevel is Map) {
      errorsByLevel = byLevel.map((key, value) {
        return MapEntry(key.toString(), readInt(value));
      });
    }

    final byStatus = root['byStatusCode'];
    Map<String, int>? requestsByStatus;
    if (byStatus is Map) {
      requestsByStatus = byStatus.map((key, value) {
        return MapEntry(key.toString(), readInt(value));
      });
    }

    final byService = root['byService'];
    Map<String, ServiceStats>? serviceStats;
    if (byService is Map) {
      serviceStats = byService.map((key, value) {
        final name = key.toString();
        // CLS P1: byService values are objects
        // { totalRequests, errorCount, errorRate, avgDuration }.
        // Legacy bare ints still accepted (counts only, numerics null).
        // Do not invent uptime % — that is not computed server-side.
        if (value is Map) {
          final m = Map<String, dynamic>.from(value);
          final double? err = m['errorRate'] != null || m['error_rate'] != null
              ? readDouble(m['errorRate'] ?? m['error_rate'])
              : null;
          final double? latency =
              m['avgDuration'] != null ||
                      m['avgLatency'] != null ||
                      m['avg_latency'] != null
                  ? readDouble(
                      m['avgDuration'] ?? m['avgLatency'] ?? m['avg_latency'],
                    )
                  : null;
          final int? errCount =
              m['errorCount'] != null || m['error_count'] != null
                  ? readInt(m['errorCount'] ?? m['error_count'])
                  : null;
          return MapEntry(
            name,
            ServiceStats(
              serviceName: name,
              totalRequests: readInt(
                m['totalRequests'] ?? m['total_requests'] ?? m['count'],
              ),
              errorRate: err,
              avgLatency: latency,
              uptime: null,
              errorCount: errCount,
            ),
          );
        }
        return MapEntry(
          name,
          ServiceStats(
            serviceName: name,
            totalRequests: readInt(value),
            errorRate: null,
            avgLatency: null,
            uptime: null,
            errorCount: null,
          ),
        );
      });
    }

    return DashboardStats(
      totalLogs: totalLogs,
      errorRate: errorRate,
      avgLatency: avgLatency,
      requestsPerHour: totalLogs,
      serviceStats: serviceStats,
      errorsByLevel: errorsByLevel,
      requestsByStatus: requestsByStatus,
    );
  }
  
  /// Get formatted error rate as percentage
  String get formattedErrorRate => '${errorRate.toStringAsFixed(1)}%';
  
  /// Get formatted average latency
  String get formattedAvgLatency => '${avgLatency.toStringAsFixed(0)}ms';
}

/// Service-specific statistics
@JsonSerializable()
class ServiceStats {
  final String serviceName;
  final int totalRequests;
  // errorRate/avgLatency/uptime/errorCount are nullable because /logs/stats
  // does not provide them and PR-24 metrics also do not. A non-null value
  // means real backend data; null means "not reporting" (show honestly).
  final double? errorRate;
  final double? avgLatency;
  final double? uptime;
  final int? errorCount;

  /// Free-form app-specific metrics (e.g. AcademicX `students`/`activeToday`).
  /// Raw map on purpose — LogPulse must not assume any app's metric shape.
  final Map<String, dynamic>? customMetrics;

  /// When the collector last received a health/metric report for this app.
  final DateTime? lastReportedAt;

  /// Distinct instanceIds reporting for this appId (Phase 18). Null = unknown
  /// (no metrics), not "zero instances." PR-24 does not provide a count.
  final int? instanceCount;

  /// Raw wire value of `health.status` from PR-24 (e.g. `"ok"`). Distinct
  /// from the derived [healthStatus] enum used for display.
  final String? reportedHealthStatus;

  /// Raw wire value of `health.uptimeSeconds`. Not a percentage — see
  /// [formattedUptimeDuration]. Never alias into [uptime].
  final int? uptimeSeconds;
  
  ServiceStats({
    required this.serviceName,
    required this.totalRequests,
    required this.errorRate,
    required this.avgLatency,
    required this.uptime,
    required this.errorCount,
    this.customMetrics,
    this.lastReportedAt,
    this.instanceCount,
    this.reportedHealthStatus,
    this.uptimeSeconds,
  });
  
  factory ServiceStats.fromJson(Map<String, dynamic> json) => _$ServiceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceStatsToJson(this);

  /// Whether log-derived per-service numerics are present (CLS P1 summary
  /// `byService` supplies errorRate + avgDuration). Uptime % is optional and
  /// not required — the collector does not compute it today.
  bool get hasHealthMetrics => errorRate != null && avgLatency != null;

  /// Whether the collector reported a real `health.status` string (PR-24).
  /// Independent of the numeric [hasHealthMetrics] fields.
  bool get hasReportedHealth =>
      reportedHealthStatus != null && reportedHealthStatus!.isNotEmpty;

  /// Whether free-form custom metrics exist and are non-empty.
  bool get hasCustomMetrics =>
      customMetrics != null && customMetrics!.isNotEmpty;
  
  /// Display health for the card dot/pulse.
  ///
  /// Priority:
  /// 1. Numeric metrics present → derive from [errorRate] thresholds
  /// 2. Else raw reported status present → map wire string
  /// 3. Else → [HealthStatus.unknown]
  HealthStatus get healthStatus {
    if (hasHealthMetrics) {
      return healthFromErrorRate(errorRate);
    }
    if (hasReportedHealth) {
      return _mapReportedHealthStatus(reportedHealthStatus!);
    }
    return HealthStatus.unknown;
  }

  /// Shared error-rate thresholds for any surface that shows a status color
  /// from log aggregates: under 1% healthy, under 5% degraded, else unhealthy.
  /// Null → [HealthStatus.unknown] (honest empty, not fabricated healthy).
  static HealthStatus healthFromErrorRate(double? errorRate) {
    if (errorRate == null) return HealthStatus.unknown;
    if (errorRate < 1.0) return HealthStatus.healthy;
    if (errorRate < 5.0) return HealthStatus.degraded;
    return HealthStatus.unhealthy;
  }

  /// Maps the collector's raw health-status string to a display enum.
  ///
  /// Write-validated vocabulary on `POST /metrics/health` (CLS P0):
  /// `ok | degraded | error | starting | stopping`.
  /// Unknown non-empty values → degraded (conservative: not healthy).
  static HealthStatus _mapReportedHealthStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'ok':
        return HealthStatus.healthy;
      case 'error':
        return HealthStatus.unhealthy;
      case 'degraded':
      case 'starting':
      case 'stopping':
        return HealthStatus.degraded;
      default:
        return HealthStatus.degraded;
    }
  }
  
  /// Formatted uptime **percentage**, or an em dash when not reporting.
  /// Do not use for PR-24's seconds-based uptime.
  String get formattedUptime => uptime == null ? '—' : '${uptime!.toStringAsFixed(1)}%';

  /// Human-readable duration from [uptimeSeconds] (e.g. `2h 15m`, `45m`, `12s`).
  /// Em dash when [uptimeSeconds] is null.
  String get formattedUptimeDuration {
    final seconds = uptimeSeconds;
    if (seconds == null) return '—';
    if (seconds < 0) return '—';
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      final rem = seconds % 60;
      return rem == 0 ? '${minutes}m' : '${minutes}m ${rem}s';
    }
    final hours = minutes ~/ 60;
    final remMin = minutes % 60;
    if (hours < 48) {
      return remMin == 0 ? '${hours}h' : '${hours}h ${remMin}m';
    }
    final days = hours ~/ 24;
    final remHours = hours % 24;
    return remHours == 0 ? '${days}d' : '${days}d ${remHours}h';
  }

  ServiceStats copyWith({
    String? serviceName,
    int? totalRequests,
    double? errorRate,
    double? avgLatency,
    double? uptime,
    int? errorCount,
    Map<String, dynamic>? customMetrics,
    DateTime? lastReportedAt,
    int? instanceCount,
    String? reportedHealthStatus,
    int? uptimeSeconds,
    bool clearCustomMetrics = false,
    bool clearLastReportedAt = false,
    bool clearInstanceCount = false,
    bool clearReportedHealthStatus = false,
    bool clearUptimeSeconds = false,
  }) {
    return ServiceStats(
      serviceName: serviceName ?? this.serviceName,
      totalRequests: totalRequests ?? this.totalRequests,
      errorRate: errorRate ?? this.errorRate,
      avgLatency: avgLatency ?? this.avgLatency,
      uptime: uptime ?? this.uptime,
      errorCount: errorCount ?? this.errorCount,
      customMetrics:
          clearCustomMetrics ? null : (customMetrics ?? this.customMetrics),
      lastReportedAt: clearLastReportedAt
          ? null
          : (lastReportedAt ?? this.lastReportedAt),
      instanceCount: clearInstanceCount
          ? null
          : (instanceCount ?? this.instanceCount),
      reportedHealthStatus: clearReportedHealthStatus
          ? null
          : (reportedHealthStatus ?? this.reportedHealthStatus),
      uptimeSeconds: clearUptimeSeconds
          ? null
          : (uptimeSeconds ?? this.uptimeSeconds),
    );
  }
}

/// Health status enum
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}
