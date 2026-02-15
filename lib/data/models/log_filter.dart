/// Log filter parameters
class LogFilter {
  final String? service;
  final String? level;
  final int? statusCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;
  final int limit;
  final int offset;
  
  LogFilter({
    this.service,
    this.level,
    this.statusCode,
    this.startDate,
    this.endDate,
    this.searchQuery,
    this.limit = 20,
    this.offset = 0,
  });
  
  LogFilter copyWith({
    String? service,
    String? level,
    int? statusCode,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    return LogFilter(
      service: service ?? this.service,
      level: level ?? this.level,
      statusCode: statusCode ?? this.statusCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return service != null ||
        level != null ||
        statusCode != null ||
        startDate != null ||
        endDate != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
  
  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (service != null) count++;
    if (level != null) count++;
    if (statusCode != null) count++;
    if (startDate != null || endDate != null) count++;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    return count;
  }
  
  /// Convert to query parameters
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    
    if (service != null) params['service'] = service!;
    if (level != null) params['level'] = level!;
    if (statusCode != null) params['statusCode'] = statusCode.toString();
    if (startDate != null) params['from'] = startDate!.toIso8601String();
    if (endDate != null) params['to'] = endDate!.toIso8601String();
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery!;
    }
    params['limit'] = limit.toString();
    params['skip'] = offset.toString();
    
    return params;
  }
}
