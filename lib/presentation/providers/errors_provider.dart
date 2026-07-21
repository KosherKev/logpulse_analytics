import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/error_group.dart';
import '../../data/repositories/errors_repository.dart';
import 'service_providers.dart';

/// Errors Provider — loads server-side groups (CLS P2) with client fallback.
final errorsProvider =
    StateNotifierProvider<ErrorsNotifier, ErrorsState>((ref) {
  final repository = ref.watch(errorsRepositoryProvider);
  return ErrorsNotifier(repository);
});

class ErrorsState {
  final List<ErrorGroup> errorGroups;
  final bool isLoading;
  final String? error;
  final String timeRange;

  ErrorsState({
    this.errorGroups = const [],
    this.isLoading = false,
    this.error,
    this.timeRange = 'last_24h',
  });

  ErrorsState copyWith({
    List<ErrorGroup>? errorGroups,
    bool? isLoading,
    String? error,
    String? timeRange,
  }) {
    return ErrorsState(
      errorGroups: errorGroups ?? this.errorGroups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

class ErrorsNotifier extends StateNotifier<ErrorsState> {
  final ErrorsRepository _repository;

  ErrorsNotifier(this._repository) : super(ErrorsState());

  Future<void> loadErrors({String? timeRange}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final range = timeRange ?? state.timeRange;
      final groups = await _repository.getErrorGroups(timeRange: range);

      state = state.copyWith(
        errorGroups: groups,
        isLoading: false,
        timeRange: range,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
