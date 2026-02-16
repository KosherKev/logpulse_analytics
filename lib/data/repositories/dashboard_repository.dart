import '../models/dashboard_stats.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
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

  /// Fetch time-series data for traffic and error rates based on recent logs
  Future<List<TimeSeriesPoint>> getErrorTrafficSeries({String? timeRange}) async {
    try {
      final now = DateTime.now().toUtc();
      final range = timeRange ?? 'last_24h';
      final from = _calculateFrom(now, range);
      final bucketDuration = _bucketDurationForRange(range);

      final filter = LogFilter(
        startDate: from,
        endDate: now,
        limit: 1000,
        offset: 0,
      );

      final logs = await _apiService.getLogs(filter);
      if (logs.isEmpty) {
        return [];
      }

      final totalMillis = now.millisecondsSinceEpoch - from.millisecondsSinceEpoch;
      final bucketMillis = bucketDuration.inMilliseconds;
      final bucketCount = (totalMillis / bucketMillis).ceil().clamp(1, 100);

      final totals = List<int>.filled(bucketCount, 0);
      final errors = List<int>.filled(bucketCount, 0);

      for (final LogEntry log in logs) {
        final ts = log.timestamp.toUtc().millisecondsSinceEpoch;
        if (ts < from.millisecondsSinceEpoch || ts > now.millisecondsSinceEpoch) {
          continue;
        }
        final index = ((ts - from.millisecondsSinceEpoch) / bucketMillis)
            .floor()
            .clamp(0, bucketCount - 1);
        totals[index] += 1;
        if (log.isError) {
          errors[index] += 1;
        }
      }

      final points = <TimeSeriesPoint>[];
      for (var i = 0; i < bucketCount; i++) {
        final bucketStart = from.add(Duration(milliseconds: bucketMillis * i));
        points.add(
          TimeSeriesPoint(
            timestamp: bucketStart,
            totalCount: totals[i],
            errorCount: errors[i],
          ),
        );
      }

      return points;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to build time-series data: ${e.toString()}');
    }
  }

  DateTime _calculateFrom(DateTime now, String timeRange) {
    switch (timeRange) {
      case 'last_hour':
        return now.subtract(const Duration(hours: 1));
      case 'last_7d':
        return now.subtract(const Duration(days: 7));
      case 'last_30d':
        return now.subtract(const Duration(days: 30));
      case 'last_24h':
      default:
        return now.subtract(const Duration(hours: 24));
    }
  }

  Duration _bucketDurationForRange(String timeRange) {
    switch (timeRange) {
      case 'last_hour':
        return const Duration(minutes: 5);
      case 'last_7d':
        return const Duration(hours: 12);
      case 'last_30d':
        return const Duration(days: 1);
      case 'last_24h':
      default:
        return const Duration(hours: 1);
    }
  }
}
