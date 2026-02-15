import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/repositories/logs_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../core/constants/app_constants.dart';

/// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Local Storage Service Provider
final localStorageProvider = FutureProvider<LocalStorageService>((ref) async {
  return await LocalStorageService.getInstance();
});

/// Logs Repository Provider
final logsRepositoryProvider = Provider<LogsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LogsRepository(apiService);
});

/// Dashboard Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DashboardRepository(apiService);
});

/// API Configuration State Provider
final apiConfigProvider = StateNotifierProvider<ApiConfigNotifier, ApiConfigState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ApiConfigNotifier(apiService);
});

/// API Configuration State
class ApiConfigState {
  final String? baseUrl;
  final String? apiKey;
  final bool isConfigured;
  final bool isLoading;
  final String? error;

  ApiConfigState({
    this.baseUrl,
    this.apiKey,
    this.isConfigured = false,
    this.isLoading = false,
    this.error,
  });

  ApiConfigState copyWith({
    String? baseUrl,
    String? apiKey,
    bool? isConfigured,
    bool? isLoading,
    String? error,
  }) {
    return ApiConfigState(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// API Configuration Notifier
class ApiConfigNotifier extends StateNotifier<ApiConfigState> {
  final ApiService _apiService;

  ApiConfigNotifier(this._apiService) : super(ApiConfigState());

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final storage = await LocalStorageService.getInstance();
      var baseUrl = storage.getApiUrl();
      var apiKey = storage.getApiKey();

      baseUrl ??= AppConstants.defaultApiBaseUrl;

      const envApiKey =
          String.fromEnvironment('LOGPULSE_API_KEY', defaultValue: '');
      if ((apiKey == null || apiKey.isEmpty) && envApiKey.isNotEmpty) {
        apiKey = envApiKey;
        await storage.setApiKey(apiKey);
      }

      if (baseUrl.isNotEmpty && apiKey != null && apiKey.isNotEmpty) {
        await storage.setApiUrl(baseUrl);
        _apiService.configure(baseUrl: baseUrl, apiKey: apiKey);
        state = state.copyWith(
          baseUrl: baseUrl,
          apiKey: apiKey,
          isConfigured: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isConfigured: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> configure({required String baseUrl, required String apiKey}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.setApiUrl(baseUrl);
      await storage.setApiKey(apiKey);
      
      _apiService.configure(baseUrl: baseUrl, apiKey: apiKey);
      
      state = state.copyWith(
        baseUrl: baseUrl,
        apiKey: apiKey,
        isConfigured: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> clearConfig() async {
    try {
      final storage = await LocalStorageService.getInstance();
      await storage.remove('api_url');
      await storage.remove('api_key');
      
      state = ApiConfigState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
