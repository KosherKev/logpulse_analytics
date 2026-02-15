import '../models/dashboard_stats.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

/// Repository for dashboard operations
class DashboardRepository {
  final ApiService _apiService;
  
  DashboardRepository(this._apiService);
  
  /// Fetch dashboard statistics
  Future<DashboardStats> getStats({String? timeRange}) async {
    try {
      return await _apiService.getDashboardStats(timeRange: timeRange);
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
}
