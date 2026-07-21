import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_summary.dart';
import '../../data/repositories/services_repository.dart';
import '../../core/errors/exceptions.dart';
import 'service_providers.dart';

/// Catalog list for services.
final servicesListProvider =
    StateNotifierProvider<ServicesListNotifier, ServicesListState>((ref) {
  final repo = ref.watch(servicesRepositoryProvider);
  return ServicesListNotifier(repo);
});

class ServicesListState {
  final List<ServiceSummary> services;
  final bool isLoading;
  final String? error;
  final String timeRange;

  ServicesListState({
    this.services = const [],
    this.isLoading = false,
    this.error,
    this.timeRange = 'last_24h',
  });

  ServicesListState copyWith({
    List<ServiceSummary>? services,
    bool? isLoading,
    String? error,
    String? timeRange,
  }) {
    return ServicesListState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      timeRange: timeRange ?? this.timeRange,
    );
  }
}

class ServicesListNotifier extends StateNotifier<ServicesListState> {
  final ServicesRepository _repository;

  ServicesListNotifier(this._repository) : super(ServicesListState());

  Future<void> load({String? timeRange}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final range = timeRange ?? state.timeRange;
      final list = await _repository.listServices(timeRange: range);
      state = state.copyWith(
        services: list,
        isLoading: false,
        timeRange: range,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Single service detail (family by name).
final serviceDetailProvider =
    FutureProvider.family<ServiceDetail, String>((ref, name) async {
  final repo = ref.watch(servicesRepositoryProvider);
  return repo.getService(name);
});
