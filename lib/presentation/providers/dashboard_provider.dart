import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_stats.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../core/errors/exceptions.dart';
import 'service_providers.dart';

/// Dashboard State Provider
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repository);
});

/// Dashboard State
class DashboardState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? error;
  final String timeRange;
  final DateTime? lastUpdated;

  DashboardState({
    this.stats,
    this.isLoading = false,
    this.error,
    this.timeRange = 'last_24h',
    this.lastUpdated,
  });

  DashboardState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? error,
    String? timeRange,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      timeRange: timeRange ?? this.timeRange,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Dashboard Notifier
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(DashboardState());

  Future<void> loadStats({String? timeRange}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _repository.getStats(
        timeRange: timeRange ?? state.timeRange,
      );

      state = state.copyWith(
        stats: stats,
        isLoading: false,
        timeRange: timeRange ?? state.timeRange,
        lastUpdated: DateTime.now(),
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard stats: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }

  void setTimeRange(String timeRange) {
    if (timeRange != state.timeRange) {
      state = state.copyWith(timeRange: timeRange);
      loadStats(timeRange: timeRange);
    }
  }
}

/// Service Health Provider
final serviceHealthProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return await repository.checkHealth();
});
