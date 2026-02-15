import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/log_entry.dart';
import '../../data/models/log_filter.dart';
import '../../data/repositories/logs_repository.dart';
import '../../core/errors/exceptions.dart';
import 'service_providers.dart';

/// Logs State Provider
final logsProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final repository = ref.watch(logsRepositoryProvider);
  return LogsNotifier(repository);
});

/// Logs State
class LogsState {
  final List<LogEntry> logs;
  final LogFilter filter;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int totalCount;

  LogsState({
    this.logs = const [],
    LogFilter? filter,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.totalCount = 0,
  }) : filter = filter ?? LogFilter();

  LogsState copyWith({
    List<LogEntry>? logs,
    LogFilter? filter,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? totalCount,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Logs Notifier
class LogsNotifier extends StateNotifier<LogsState> {
  final LogsRepository _repository;

  LogsNotifier(this._repository) : super(LogsState());

  Future<void> loadLogs({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        filter: state.filter.copyWith(offset: 0),
      );
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final logs = await _repository.getLogs(state.filter);

      if (refresh) {
        state = state.copyWith(
          logs: logs,
          isLoading: false,
          hasMore: logs.length >= state.filter.limit,
          totalCount: logs.length,
        );
      } else {
        state = state.copyWith(
          logs: [...state.logs, ...logs],
          isLoading: false,
          hasMore: logs.length >= state.filter.limit,
          totalCount: state.totalCount + logs.length,
        );
      }
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load logs: ${e.toString()}',
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final newFilter = state.filter.copyWith(
      offset: state.logs.length,
    );

    state = state.copyWith(filter: newFilter);
    await loadLogs();
  }

  void updateFilter(LogFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> applyFilter(LogFilter filter) async {
    state = state.copyWith(
      filter: filter.copyWith(offset: 0),
      logs: [],
    );
    await loadLogs(refresh: true);
  }

  void clearFilter() {
    state = state.copyWith(
      filter: LogFilter(),
      logs: [],
    );
    loadLogs(refresh: true);
  }

  Future<void> search(String query) async {
    final filter = state.filter.copyWith(
      searchQuery: query,
      offset: 0,
    );
    await applyFilter(filter);
  }
}

/// Single Log Provider (by ID)
final logByIdProvider = FutureProvider.family<LogEntry, String>((ref, id) async {
  final repository = ref.watch(logsRepositoryProvider);
  return await repository.getLogById(id);
});

/// Logs by Trace ID Provider
final logsByTraceIdProvider = FutureProvider.family<List<LogEntry>, String>((ref, traceId) async {
  final repository = ref.watch(logsRepositoryProvider);
  return await repository.getLogsByTraceId(traceId);
});
