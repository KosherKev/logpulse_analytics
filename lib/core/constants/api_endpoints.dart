/// API endpoint paths
class ApiEndpoints {
  // Base
  static const String logs = '/logs';
  static const String stats = '/logs/stats/summary';
  
  // Logs
  static String logById(String id) => '/logs/$id';
  static String logsByTraceId(String traceId) => '/logs?traceId=$traceId';
  
  // Health
  static const String health = '/health';
  static const String ready = '/ready';
  
  // Query Builders
  static String buildLogsQuery({
    String? service,
    String? level,
    int? statusCode,
    String? after,
    String? before,
    int? limit,
    int? offset,
    String? search,
  }) {
    final params = <String, String>{};
    
    if (service != null) params['service'] = service;
    if (level != null) params['level'] = level;
    if (statusCode != null) params['statusCode'] = statusCode.toString();
    if (after != null) params['after'] = after;
    if (before != null) params['before'] = before;
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
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
}
