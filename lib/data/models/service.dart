import 'package:json_annotation/json_annotation.dart';

part 'service.g.dart';

/// Service model
@JsonSerializable()
class Service {
  final String name;
  final String? displayName;
  final int totalRequests;
  final double errorRate;
  final double avgLatency;
  final double uptime;
  final DateTime? lastSeen;
  final Map<String, EndpointStats>? endpoints;
  
  Service({
    required this.name,
    this.displayName,
    required this.totalRequests,
    required this.errorRate,
    required this.avgLatency,
    required this.uptime,
    this.lastSeen,
    this.endpoints,
  });
  
  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceToJson(this);
  
  /// Get display name or fallback to name
  String get label => displayName ?? name;
  
  /// Calculate health score (0-100)
  double get healthScore {
    final uptimeScore = uptime;
    final errorScore = (1 - (errorRate / 100)) * 100;
    final latencyScore = avgLatency < 100 ? 100 : (avgLatency < 500 ? 75 : 50);
    
    return (uptimeScore * 0.4 + errorScore * 0.4 + latencyScore * 0.2);
  }
  
  /// Get health status
  String get healthStatus {
    final score = healthScore;
    if (score >= 95) return 'Excellent';
    if (score >= 85) return 'Good';
    if (score >= 70) return 'Fair';
    return 'Poor';
  }
  
  /// Check if service is healthy
  bool get isHealthy => healthScore >= 85;
}

/// Endpoint statistics
@JsonSerializable()
class EndpointStats {
  final String path;
  final String method;
  final int requestCount;
  final double errorRate;
  final double avgLatency;
  final int errorCount;
  
  EndpointStats({
    required this.path,
    required this.method,
    required this.requestCount,
    required this.errorRate,
    required this.avgLatency,
    required this.errorCount,
  });
  
  factory EndpointStats.fromJson(Map<String, dynamic> json) => _$EndpointStatsFromJson(json);
  Map<String, dynamic> toJson() => _$EndpointStatsToJson(this);
  
  /// Get formatted endpoint name
  String get formattedEndpoint => '$method $path';
}
