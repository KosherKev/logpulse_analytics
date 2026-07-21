import '../models/error_group.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../services/api_service.dart';
import '../../core/errors/exceptions.dart';

/// Error groups — prefers CLS P2 server aggregation, falls back to client-side
/// grouping of a logs page when the route is missing (404).
class ErrorsRepository {
  final ApiService _apiService;

  ErrorsRepository(this._apiService);

  Future<List<ErrorGroup>> getErrorGroups({
    String? timeRange,
    String? service,
    int? limit,
  }) async {
    try {
      return await _apiService.getErrorGroups(
        timeRange: timeRange,
        service: service,
        limit: limit,
      );
    } on AppException catch (e) {
      // Missing route on older backends only — soft-fail to client grouping.
      if (e is ApiException && e.statusCode == 404) {
        return _clientSideGroups();
      }
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch error groups: ${e.toString()}');
    }
  }

  Future<List<ErrorGroup>> _clientSideGroups() async {
    final page = await _apiService.getLogs(
      LogFilter(limit: 200, offset: 0),
    );
    final errorLogs = page.logs.where((log) => log.isError).toList();
    return _groupErrors(errorLogs);
  }

  List<ErrorGroup> _groupErrors(List<LogEntry> errorLogs) {
    final Map<String, List<LogEntry>> grouped = {};
    for (final log in errorLogs) {
      final message = log.displayError;
      grouped.putIfAbsent(message, () => []).add(log);
    }

    return grouped.entries.map((entry) {
      final instances = entry.value;
      final services = instances.map((e) => e.service).toSet().toList();
      final sorted = [...instances]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return ErrorGroup(
        id: entry.key.hashCode.toString(),
        message: entry.key,
        errorCode: instances.first.error?.code,
        count: instances.length,
        services: services,
        firstSeen: sorted.first.timestamp,
        lastSeen: sorted.last.timestamp,
        stackTrace: instances.first.error?.stack,
        instances: instances,
        sampleTraceId: instances.first.traceId,
        trend: _calculateTrend(instances),
      );
    }).toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }

  TrendDirection _calculateTrend(List<LogEntry> instances) {
    if (instances.length < 2) return TrendDirection.stable;
    final recentCount = instances
        .where((e) => DateTime.now().difference(e.timestamp).inHours < 1)
        .length;
    final olderCount = instances.length - recentCount;
    if (recentCount > olderCount) return TrendDirection.increasing;
    if (recentCount < olderCount) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }
}
