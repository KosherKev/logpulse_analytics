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
        final count = readInt(value);
        final name = key.toString();
        // NOTE: /logs/stats/summary's byService only returns request counts.
        // There is no real per-service errorRate/avgLatency/uptime yet — the
        // metrics *read* API (@bevingh/telemetry → central-logging-service)
        // that would supply this doesn't exist (see TELEMETRY_PATCH_PLAN.md
        // Phase 16). Previously this synthesized a fake `uptime: 100.0` and
        // copied the *global* errorRate/avgLatency onto every service, which
        // reads as confident per-service data that isn't real. Leaving these
        // null so the UI can show an honest "not reporting" state instead.
        return MapEntry(
          name,
          ServiceStats(
            serviceName: name,
            totalRequests: count,
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
  // errorRate/avgLatency/uptime/errorCount are nullable because there is no
  // real per-service source for them yet (see DashboardStats.fromApiJson).
  // A non-null value here means it came from real backend data; null means
  // "not reporting" and should be shown honestly, not defaulted to a number.
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
  /// (no metrics), not "zero instances."
  final int? instanceCount;
  
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
  });
  
  factory ServiceStats.fromJson(Map<String, dynamic> json) => _$ServiceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceStatsToJson(this);

  /// Whether this service has real health metrics reported, as opposed to
  /// no data at all.
  bool get hasHealthMetrics => errorRate != null && avgLatency != null && uptime != null;

  /// Whether free-form custom metrics exist and are non-empty.
  bool get hasCustomMetrics =>
      customMetrics != null && customMetrics!.isNotEmpty;
  
  /// Get health status based on error rate. Returns [HealthStatus.unknown]
  /// when no real metrics have been reported for this service yet.
  HealthStatus get healthStatus {
    if (!hasHealthMetrics) return HealthStatus.unknown;
    if (errorRate! < 1.0) return HealthStatus.healthy;
    if (errorRate! < 5.0) return HealthStatus.degraded;
    return HealthStatus.unhealthy;
  }
  
  /// Get formatted uptime percentage, or an em dash when not reporting.
  String get formattedUptime => uptime == null ? '—' : '${uptime!.toStringAsFixed(1)}%';

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
    bool clearCustomMetrics = false,
    bool clearLastReportedAt = false,
    bool clearInstanceCount = false,
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
