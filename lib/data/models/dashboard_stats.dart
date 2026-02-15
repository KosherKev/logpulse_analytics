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
        return MapEntry(
          name,
          ServiceStats(
            serviceName: name,
            totalRequests: count,
            errorRate: errorRate,
            avgLatency: avgLatency,
            uptime: 100.0,
            errorCount: 0,
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
  final double errorRate;
  final double avgLatency;
  final double uptime;
  final int errorCount;
  
  ServiceStats({
    required this.serviceName,
    required this.totalRequests,
    required this.errorRate,
    required this.avgLatency,
    required this.uptime,
    required this.errorCount,
  });
  
  factory ServiceStats.fromJson(Map<String, dynamic> json) => _$ServiceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceStatsToJson(this);
  
  /// Get health status based on error rate
  HealthStatus get healthStatus {
    if (errorRate < 1.0) return HealthStatus.healthy;
    if (errorRate < 5.0) return HealthStatus.degraded;
    return HealthStatus.unhealthy;
  }
  
  /// Get formatted uptime percentage
  String get formattedUptime => '${uptime.toStringAsFixed(1)}%';
}

/// Health status enum
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  unknown,
}
