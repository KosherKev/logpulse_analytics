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
