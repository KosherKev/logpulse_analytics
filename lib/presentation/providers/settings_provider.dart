import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/local_storage_service.dart';

/// Settings State Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Settings State
class SettingsState {
  final String themeMode;
  final bool autoRefresh;
  final int refreshInterval;
  final String? apiUrl;
  final bool hasApiKey;
  final bool isLoading;

  SettingsState({
    this.themeMode = 'system',
    this.autoRefresh = true,
    this.refreshInterval = 30,
    this.apiUrl,
    this.hasApiKey = false,
    this.isLoading = false,
  });

  SettingsState copyWith({
    String? themeMode,
    bool? autoRefresh,
    int? refreshInterval,
    String? apiUrl,
    bool? hasApiKey,
    bool? isLoading,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      apiUrl: apiUrl ?? this.apiUrl,
      hasApiKey: hasApiKey ?? this.hasApiKey,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      final storage = await LocalStorageService.getInstance();

      state = state.copyWith(
        themeMode: storage.getThemeMode(),
        autoRefresh: storage.getAutoRefresh(),
        refreshInterval: storage.getRefreshInterval(),
        apiUrl: storage.getApiUrl(),
        hasApiKey: storage.getApiKey() != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setThemeMode(String mode) async {
    final storage = await LocalStorageService.getInstance();
    await storage.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAutoRefresh(bool enabled) async {
    final storage = await LocalStorageService.getInstance();
    await storage.setAutoRefresh(enabled);
    state = state.copyWith(autoRefresh: enabled);
  }

  Future<void> setRefreshInterval(int seconds) async {
    final storage = await LocalStorageService.getInstance();
    await storage.setRefreshInterval(seconds);
    state = state.copyWith(refreshInterval: seconds);
  }

  Future<void> clearCache() async {
    final storage = await LocalStorageService.getInstance();
    // Clear only cache, not settings
    // Implementation depends on cache strategy
  }
}

/// Theme Mode Provider
final themeModeProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.themeMode;
});

/// Auto Refresh Provider
final autoRefreshProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.autoRefresh;
});
