import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

/// Repository for log operations
class LogsRepository {
  final ApiService _apiService;
  
  LogsRepository(this._apiService);
  
  /// Fetch logs with filters
  Future<List<LogEntry>> getLogs(LogFilter filter) async {
    try {
      return await _apiService.getLogs(filter);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch logs: ${e.toString()}');
    }
  }
  
  /// Fetch logs by trace ID
  Future<List<LogEntry>> getLogsByTraceId(String traceId) async {
    try {
      return await _apiService.getLogsByTraceId(traceId);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch logs by trace ID: ${e.toString()}');
    }
  }
  
  /// Search logs
  Future<List<LogEntry>> searchLogs(String query, {LogFilter? filter}) async {
    try {
      final searchFilter = filter?.copyWith(searchQuery: query) ??
          LogFilter(searchQuery: query);
      return await _apiService.getLogs(searchFilter);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to search logs: ${e.toString()}');
    }
  }
}
