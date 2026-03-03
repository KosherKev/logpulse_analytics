import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';
import '../../data/models/api_connection_profile.dart';
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
  final List<ApiConnectionProfile> profiles;
  final String? activeProfileId;
  final bool isFirstRun;

  ApiConfigState({
    this.baseUrl,
    this.apiKey,
    this.isConfigured = false,
    this.isLoading = false,
    this.error,
    this.profiles = const [],
    this.activeProfileId,
    this.isFirstRun = false,
  });

  ApiConfigState copyWith({
    String? baseUrl,
    String? apiKey,
    bool? isConfigured,
    bool? isLoading,
    String? error,
    List<ApiConnectionProfile>? profiles,
    String? activeProfileId,
    bool? isFirstRun,
  }) {
    return ApiConfigState(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isConfigured: isConfigured ?? this.isConfigured,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
      isFirstRun: isFirstRun ?? this.isFirstRun,
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
      final storageVersion = storage.getInt(AppConstants.keyStorageVersion) ?? 0;
      final profilesJson =
          storage.getString(AppConstants.keyApiProfiles);
      final activeId =
          storage.getString(AppConstants.keyActiveApiProfileId);

      List<ApiConnectionProfile> profiles = [];
      ApiConnectionProfile? activeProfile;

      if (profilesJson != null && profilesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(profilesJson) as List<dynamic>;
        profiles = decoded
            .map((e) =>
                ApiConnectionProfile.fromJson(e as Map<String, dynamic>))
            .toList();
        if (profiles.isNotEmpty) {
          activeProfile = profiles.firstWhere(
            (p) => p.id == activeId,
            orElse: () => profiles.first,
          );
          final secureKey = await storage.getProfileApiKey(activeProfile.id);
          activeProfile = activeProfile.copyWith(apiKey: secureKey ?? '');
          if ((activeProfile.apiKey.isEmpty)) {
            const envApiKey =
                String.fromEnvironment('LOGPULSE_API_KEY', defaultValue: '');
            if (envApiKey.isNotEmpty) {
              await storage.setProfileApiKey(activeProfile.id, envApiKey);
              activeProfile = activeProfile.copyWith(apiKey: envApiKey);
            }
          }
        }
      } else {
        final legacyBaseUrl = storage.getApiUrl();
        String? legacyApiKey = await storage.getProfileApiKey('default');
        legacyApiKey ??= storage.getString(AppConstants.keyApiKey);

        if (storageVersion < AppConstants.currentStorageVersion) {
          if (legacyBaseUrl != null && legacyBaseUrl.isNotEmpty) {
            final profile = ApiConnectionProfile(
              id: 'default',
              name: 'Default',
              baseUrl: legacyBaseUrl,
              apiKey: legacyApiKey ?? '',
            );
            profiles = [profile];
            activeProfile = profile;
            await _persistProfiles(storage, profiles, profile.id);
            if ((legacyApiKey ?? '').isNotEmpty) {
              await storage.setProfileApiKey(profile.id, legacyApiKey!);
            }
          }
          await storage.setInt(AppConstants.keyStorageVersion, AppConstants.currentStorageVersion);
        }

        const envApiKey =
            String.fromEnvironment('LOGPULSE_API_KEY', defaultValue: '');
        const envBaseUrl =
            String.fromEnvironment('LOGPULSE_BASE_URL', defaultValue: '');
        if (activeProfile == null && envBaseUrl.isNotEmpty) {
          final profile = ApiConnectionProfile(
            id: 'default',
            name: 'Default',
            baseUrl: envBaseUrl,
            apiKey: envApiKey,
          );
          profiles = [profile];
          activeProfile = profile;
          await _persistProfiles(storage, profiles, profile.id);
          if (envApiKey.isNotEmpty) {
            await storage.setProfileApiKey(profile.id, envApiKey);
            activeProfile = activeProfile.copyWith(apiKey: envApiKey);
          }
        } else if (activeProfile != null && (activeProfile.apiKey.isEmpty) && envApiKey.isNotEmpty) {
          await storage.setProfileApiKey(activeProfile.id, envApiKey);
          activeProfile = activeProfile.copyWith(apiKey: envApiKey);
        }
      }

      if (activeProfile != null) {
        _apiService.configure(
          baseUrl: activeProfile.baseUrl,
          apiKey: activeProfile.apiKey,
        );
        state = state.copyWith(
          baseUrl: activeProfile.baseUrl,
          apiKey: activeProfile.apiKey,
          isConfigured: true,
          isLoading: false,
          profiles: profiles,
          activeProfileId: activeProfile.id,
          isFirstRun: false,
        );
      } else {
        state = state.copyWith(
          isConfigured: false,
          isLoading: false,
          profiles: profiles,
          isFirstRun: true,
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
      final currentProfiles = [...state.profiles];
      ApiConnectionProfile? activeProfile;

      if (state.activeProfileId != null) {
        final index = currentProfiles
            .indexWhere((p) => p.id == state.activeProfileId);
        if (index >= 0) {
          currentProfiles[index] = currentProfiles[index].copyWith(
            baseUrl: baseUrl,
          );
          activeProfile = currentProfiles[index];
          await storage.setProfileApiKey(activeProfile.id, apiKey);
        }
      }

      activeProfile ??= ApiConnectionProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Connection ${currentProfiles.length + 1}',
        baseUrl: baseUrl,
        apiKey: apiKey,
      );

      if (!currentProfiles.contains(activeProfile)) {
        currentProfiles.add(activeProfile);
        await storage.setProfileApiKey(activeProfile.id, apiKey);
      }

      await _persistProfiles(storage, currentProfiles, activeProfile.id);

      _apiService.configure(
        baseUrl: activeProfile.baseUrl,
        apiKey: activeProfile.apiKey,
      );

      state = state.copyWith(
        baseUrl: activeProfile.baseUrl,
        apiKey: activeProfile.apiKey,
        isConfigured: true,
        isLoading: false,
        profiles: currentProfiles,
        activeProfileId: activeProfile.id,
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
      await storage.remove(AppConstants.keyApiProfiles);
      await storage.remove(AppConstants.keyActiveApiProfileId);
      for (final p in state.profiles) {
        await storage.removeProfileApiKey(p.id);
      }
      
      state = ApiConfigState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addProfile({
    required String name,
    required String baseUrl,
    required String apiKey,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final storage = await LocalStorageService.getInstance();
      final profiles = [...state.profiles];

      final profile = ApiConnectionProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        baseUrl: baseUrl,
        apiKey: apiKey,
      );

      profiles.add(profile);
      await _persistProfiles(storage, profiles, profile.id);

      _apiService.configure(baseUrl: baseUrl, apiKey: apiKey);

      state = state.copyWith(
        baseUrl: baseUrl,
        apiKey: apiKey,
        isConfigured: true,
        isLoading: false,
        profiles: profiles,
        activeProfileId: profile.id,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> setActiveProfile(String profileId) async {
    if (state.profiles.isEmpty) {
      return;
    }

    final profile = state.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => state.profiles.first,
    );

    final storage = await LocalStorageService.getInstance();
    await _persistProfiles(storage, state.profiles, profile.id);

    _apiService.configure(
      baseUrl: profile.baseUrl,
      apiKey: (await storage.getProfileApiKey(profile.id)) ?? '',
    );

    state = state.copyWith(
      baseUrl: profile.baseUrl,
      apiKey: (await storage.getProfileApiKey(profile.id)) ?? '',
      isConfigured: true,
      activeProfileId: profile.id,
    );
  }

  Future<void> removeProfile(String profileId) async {
    final profiles =
        state.profiles.where((p) => p.id != profileId).toList(growable: false);

    final storage = await LocalStorageService.getInstance();

    String? newActiveId;
    if (profiles.isNotEmpty) {
      newActiveId = profiles.first.id;
      await _persistProfiles(storage, profiles, newActiveId);

      final active = profiles.first;
      final secureKey = await storage.getProfileApiKey(active.id);
      _apiService.configure(
        baseUrl: active.baseUrl,
        apiKey: secureKey ?? '',
      );

      state = state.copyWith(
        baseUrl: active.baseUrl,
        apiKey: secureKey ?? '',
        isConfigured: true,
        profiles: profiles,
        activeProfileId: newActiveId,
      );
    } else {
      await _persistProfiles(storage, profiles, null);
      state = ApiConfigState();
    }
    
    await storage.removeProfileApiKey(profileId);
  }

  Future<void> _persistProfiles(
    LocalStorageService storage,
    List<ApiConnectionProfile> profiles,
    String? activeId,
  ) async {
    final encoded =
        jsonEncode(profiles.map((p) => p.toJson()).toList());
    await storage.setString(AppConstants.keyApiProfiles, encoded);
    if (activeId != null) {
      await storage.setString(AppConstants.keyActiveApiProfileId, activeId);
    } else {
      await storage.remove(AppConstants.keyActiveApiProfileId);
    }
  }
}
