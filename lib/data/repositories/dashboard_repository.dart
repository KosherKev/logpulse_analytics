import '../models/dashboard_stats.dart';
import '../models/time_series_point.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

/// Repository for dashboard operations
class DashboardRepository {
  final ApiService _apiService;
  
  DashboardRepository(this._apiService);
  
  /// Fetch dashboard statistics
  Future<DashboardStats> getStats({String? timeRange}) async {
    try {
      final stats = await _apiService.getDashboardStats(timeRange: timeRange);
      final range = timeRange ?? 'last_24h';
      final hours = _hoursForRange(range);
      final reqPerHour = hours > 0 ? (stats.totalLogs / hours).round() : stats.totalLogs;
      return DashboardStats(
        totalLogs: stats.totalLogs,
        errorRate: stats.errorRate,
        avgLatency: stats.avgLatency,
        requestsPerHour: reqPerHour,
        serviceStats: stats.serviceStats,
        errorsByLevel: stats.errorsByLevel,
        requestsByStatus: stats.requestsByStatus,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }
  
  /// Check service health
  Future<bool> checkHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      return false;
    }
  }

  /// Fetch time-series data using dedicated endpoint with fallback
  Future<List<TimeSeriesPoint>> getErrorTrafficSeries({String? timeRange}) async {
    try {
      return await _apiService.getTimeSeries(timeRange: timeRange);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch time-series data: ${e.toString()}');
    }
  }

  int _hoursForRange(String timeRange) {
    switch (timeRange) {
      case 'last_hour':
        return 1;
      case 'last_7d':
        return 7 * 24;
      case 'last_30d':
        return 30 * 24;
      case 'last_24h':
      default:
        return 24;
    }
  }

}
