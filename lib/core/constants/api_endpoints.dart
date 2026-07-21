/// API endpoint paths
class ApiEndpoints {
  // Base
  static const String logs = '/logs';
  static const String stats = '/logs/stats/summary';
  static const String timeseries = '/logs/stats/timeseries';

  /// Metrics read route (PR-24): `GET /api/v1/metrics?appId=<optional>`.
  /// Latest-snapshot only — no server-side time-range filtering.
  static const String metricsSummary = '/metrics';
  
  // Logs
  static String logsByTraceId(String traceId) => '/logs?traceId=$traceId';
  
  // Health
  static const String health = '/health';
  static const String ready = '/ready';
  
  // Query Builders
  static String buildLogsQuery({
    String? service,
    String? level,
    int? statusCode,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? search,
  }) {
    final params = <String, String>{};
    
    if (service != null) params['service'] = service;
    if (level != null) params['level'] = level;
    if (statusCode != null) params['statusCode'] = statusCode.toString();
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['skip'] = offset.toString();
    if (search != null) params['search'] = search;
    
    if (params.isEmpty) return logs;
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$logs?$query';
  }
  
  static String buildStatsQuery({
    String? service,
    String? timeRange,
  }) {
    final params = <String, String>{};
    
    if (service != null) params['service'] = service;
    if (timeRange != null) params['timeRange'] = timeRange;
    
    if (params.isEmpty) return stats;
    
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '$stats?$query';
  }
  
  static String buildTimeseriesQuery({
    String? service,
    String? timeRange,
  }) {
    final params = <String, String>{};
    if (service != null) params['service'] = service;
    if (timeRange != null) params['timeRange'] = timeRange;
    if (params.isEmpty) return timeseries;
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return '$timeseries?$query';
  }

  /// Builds `GET /metrics` with optional `appId` only (PR-24 contract).
  /// Does not accept `timeRange` — the server has no time-range filter.
  static String buildMetricsSummaryQuery({
    String? appId,
  }) {
    if (appId == null || appId.isEmpty) return metricsSummary;
    return '$metricsSummary?appId=${Uri.encodeComponent(appId)}';
  }
}
