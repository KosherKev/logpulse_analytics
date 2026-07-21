/// Row from `GET /api/v1/services`.
class ServiceSummary {
  final String name;
  final String? displayName;
  final int totalRequests;
  final double? errorRate;
  final double? avgLatency;
  final DateTime? lastSeen;
  final int? instanceCount;

  const ServiceSummary({
    required this.name,
    this.displayName,
    required this.totalRequests,
    this.errorRate,
    this.avgLatency,
    this.lastSeen,
    this.instanceCount,
  });

  String get label =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : name;

  factory ServiceSummary.fromApiJson(Map<String, dynamic> json) {
    int readInt(dynamic v, {int fallback = 0}) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double? readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    DateTime? readDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v).toUtc();
        } catch (_) {}
      }
      return null;
    }

    return ServiceSummary(
      name: (json['name'] ?? json['appId'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
      totalRequests: readInt(json['totalRequests'] ?? json['total_requests']),
      errorRate: readDouble(json['errorRate'] ?? json['error_rate']),
      avgLatency: readDouble(
        json['avgLatency'] ?? json['avg_latency'] ?? json['avgDuration'],
      ),
      lastSeen: readDate(json['lastSeen'] ?? json['last_seen']),
      instanceCount: json['instanceCount'] != null || json['instance_count'] != null
          ? readInt(json['instanceCount'] ?? json['instance_count'])
          : null,
    );
  }
}

/// Endpoint row on service detail.
class EndpointStats {
  final String path;
  final String method;
  final int requestCount;
  final double? errorRate;
  final double? avgLatency;
  final int? errorCount;

  const EndpointStats({
    required this.path,
    required this.method,
    required this.requestCount,
    this.errorRate,
    this.avgLatency,
    this.errorCount,
  });

  String get formattedEndpoint => '$method $path';

  factory EndpointStats.fromApiJson(Map<String, dynamic> json) {
    int readInt(dynamic v, {int fallback = 0}) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double? readDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return EndpointStats(
      path: (json['path'] ?? '').toString(),
      method: (json['method'] ?? '').toString(),
      requestCount: readInt(json['requestCount'] ?? json['request_count']),
      errorRate: readDouble(json['errorRate'] ?? json['error_rate']),
      avgLatency: readDouble(
        json['avgLatency'] ?? json['avg_latency'] ?? json['avgDuration'],
      ),
      errorCount: json['errorCount'] != null || json['error_count'] != null
          ? readInt(json['errorCount'] ?? json['error_count'])
          : null,
    );
  }
}

/// Instance row on service detail / metrics.
class ServiceInstance {
  final String instanceId;
  final DateTime? lastSeen;
  final String? status;
  final int? uptimeSeconds;

  const ServiceInstance({
    required this.instanceId,
    this.lastSeen,
    this.status,
    this.uptimeSeconds,
  });

  factory ServiceInstance.fromApiJson(Map<String, dynamic> json) {
    DateTime? readDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v).toUtc();
        } catch (_) {}
      }
      return null;
    }

    int? readInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return ServiceInstance(
      instanceId: (json['instanceId'] ?? json['instance_id'] ?? '').toString(),
      lastSeen: readDate(json['lastSeen'] ?? json['last_seen']),
      status: json['status']?.toString(),
      uptimeSeconds: readInt(json['uptimeSeconds'] ?? json['uptime_seconds']),
    );
  }
}

/// Detail from `GET /api/v1/services/:name`.
class ServiceDetail {
  final ServiceSummary summary;
  final List<EndpointStats> endpoints;
  final String? healthStatus;
  final String? healthInstanceId;
  final int? uptimeSeconds;
  final DateTime? healthTimestamp;
  final Map<String, dynamic>? metrics;
  final List<ServiceInstance> instances;

  const ServiceDetail({
    required this.summary,
    this.endpoints = const [],
    this.healthStatus,
    this.healthInstanceId,
    this.uptimeSeconds,
    this.healthTimestamp,
    this.metrics,
    this.instances = const [],
  });

  factory ServiceDetail.fromApiJson(Map<String, dynamic> json) {
    final summary = ServiceSummary.fromApiJson(json);

    final endpoints = <EndpointStats>[];
    final epRaw = json['endpoints'];
    if (epRaw is List) {
      for (final e in epRaw) {
        if (e is Map) {
          endpoints.add(EndpointStats.fromApiJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    String? healthStatus;
    String? healthInstanceId;
    int? uptimeSeconds;
    DateTime? healthTimestamp;
    final healthRaw = json['health'];
    if (healthRaw is Map) {
      final h = Map<String, dynamic>.from(healthRaw);
      healthStatus = h['status']?.toString();
      healthInstanceId = h['instanceId']?.toString();
      final u = h['uptimeSeconds'] ?? h['uptime_seconds'];
      if (u is num) uptimeSeconds = u.toInt();
      if (u is String) uptimeSeconds = int.tryParse(u);
      final ts = h['timestamp'];
      if (ts is String) {
        try {
          healthTimestamp = DateTime.parse(ts).toUtc();
        } catch (_) {}
      }
    }

    Map<String, dynamic>? metrics;
    final mRaw = json['metrics'];
    if (mRaw is Map) {
      metrics = Map<String, dynamic>.from(mRaw);
    }

    final instances = <ServiceInstance>[];
    final iRaw = json['instances'];
    if (iRaw is List) {
      for (final i in iRaw) {
        if (i is Map) {
          instances
              .add(ServiceInstance.fromApiJson(Map<String, dynamic>.from(i)));
        }
      }
    }

    return ServiceDetail(
      summary: summary,
      endpoints: endpoints,
      healthStatus: healthStatus,
      healthInstanceId: healthInstanceId,
      uptimeSeconds: uptimeSeconds,
      healthTimestamp: healthTimestamp,
      metrics: metrics,
      instances: instances,
    );
  }
}
