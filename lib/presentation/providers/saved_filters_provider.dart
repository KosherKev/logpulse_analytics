import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/log_filter.dart';
import '../../data/services/local_storage_service.dart';
import '../../core/constants/app_constants.dart';

class SavedFilter {
  final String name;
  final LogFilter filter;

  SavedFilter({
    required this.name,
    required this.filter,
  });

  factory SavedFilter.fromJson(Map<String, dynamic> json) {
    return SavedFilter(
      name: json['name'] as String,
      filter: LogFilter.fromJson(json['filter'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filter': filter.toJson(),
    };
  }
}

class SavedFiltersState {
  final List<SavedFilter> filters;
  final bool isLoading;
  final String? error;

  SavedFiltersState({
    this.filters = const [],
    this.isLoading = false,
    this.error,
  });

  SavedFiltersState copyWith({
    List<SavedFilter>? filters,
    bool? isLoading,
    String? error,
  }) {
    return SavedFiltersState(
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SavedFiltersNotifier extends StateNotifier<SavedFiltersState> {
  SavedFiltersNotifier() : super(SavedFiltersState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final storage = await LocalStorageService.getInstance();
      final raw = storage.getString(AppConstants.keySavedLogFilters);
      if (raw == null || raw.isEmpty) {
        state = state.copyWith(filters: [], isLoading: false);
        return;
      }

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final filters = decoded
          .map((item) => SavedFilter.fromJson(item as Map<String, dynamic>))
          .toList();

      state = state.copyWith(filters: filters, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveFilter(String name, LogFilter filter) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final existing = [...state.filters];

      final index = existing.indexWhere((f) => f.name == name);
      final newFilter = SavedFilter(name: name, filter: filter);

      if (index >= 0) {
        existing[index] = newFilter;
      } else {
        existing.add(newFilter);
      }

      final encoded = jsonEncode(existing.map((f) => f.toJson()).toList());
      await storage.setString(AppConstants.keySavedLogFilters, encoded);

      state = state.copyWith(filters: existing);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFilter(String name) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final remaining =
          state.filters.where((f) => f.name != name).toList(growable: false);
      final encoded = jsonEncode(remaining.map((f) => f.toJson()).toList());
      await storage.setString(AppConstants.keySavedLogFilters, encoded);
      state = state.copyWith(filters: remaining);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final savedFiltersProvider =
    StateNotifierProvider<SavedFiltersNotifier, SavedFiltersState>((ref) {
  final notifier = SavedFiltersNotifier();
  notifier.load();
  return notifier;
});

