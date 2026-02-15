import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/error_group.dart';
import '../../data/models/log_entry.dart';
import 'logs_provider.dart';

/// Errors Provider - Groups and manages errors
final errorsProvider = StateNotifierProvider<ErrorsNotifier, ErrorsState>((ref) {
  final logsNotifier = ref.watch(logsProvider.notifier);
  return ErrorsNotifier(logsNotifier);
});

/// Errors State
class ErrorsState {
  final List<ErrorGroup> errorGroups;
  final bool isLoading;
  final String? error;

  ErrorsState({
    this.errorGroups = const [],
    this.isLoading = false,
    this.error,
  });

  ErrorsState copyWith({
    List<ErrorGroup>? errorGroups,
    bool? isLoading,
    String? error,
  }) {
    return ErrorsState(
      errorGroups: errorGroups ?? this.errorGroups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Errors Notifier
class ErrorsNotifier extends StateNotifier<ErrorsState> {
  final LogsNotifier _logsNotifier;

  ErrorsNotifier(this._logsNotifier) : super(ErrorsState());

  Future<void> loadErrors() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load error logs
      await _logsNotifier.applyFilter(
        _logsNotifier.state.filter.copyWith(level: 'error'),
      );

      final errorLogs = _logsNotifier.state.logs;

      // Group errors by message (simplified grouping)
      final groups = _groupErrors(errorLogs);

      state = state.copyWith(
        errorGroups: groups,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<ErrorGroup> _groupErrors(List<LogEntry> errorLogs) {
    final Map<String, List<LogEntry>> grouped = {};

    // Group by error message
    for (final log in errorLogs) {
      final message = log.error?.message ?? 'Unknown Error';
      grouped.putIfAbsent(message, () => []).add(log);
    }

    // Create error groups
    return grouped.entries.map((entry) {
      final instances = entry.value;
      final services = instances.map((e) => e.service).toSet().toList();

      return ErrorGroup(
        id: entry.key.hashCode.toString(),
        message: entry.key,
        errorCode: instances.first.error?.code,
        count: instances.length,
        services: services,
        firstSeen: instances.last.timestamp,
        lastSeen: instances.first.timestamp,
        stackTrace: instances.first.error?.stack,
        instances: instances,
        trend: _calculateTrend(instances),
      );
    }).toList()
      ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
  }

  TrendDirection _calculateTrend(List<LogEntry> instances) {
    if (instances.length < 2) return TrendDirection.stable;

    final recentCount = instances
        .where((e) => 
            DateTime.now().difference(e.timestamp).inHours < 1)
        .length;
    
    final olderCount = instances.length - recentCount;

    if (recentCount > olderCount) return TrendDirection.increasing;
    if (recentCount < olderCount) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }
}
