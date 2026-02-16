/// App-wide constants
class AppConstants {
  // API Configuration
  static const String defaultApiBaseUrl =
      'https://central-logging-service-858865328729.europe-west1.run.app';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/$apiVersion';
  
  // Storage Keys
  static const String keyApiUrl = 'api_url';
  static const String keyApiKey = 'api_key';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAutoRefresh = 'auto_refresh';
  static const String keyRefreshInterval = 'refresh_interval';
  static const String keySavedLogFilters = 'saved_log_filters';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const int maxCachedLogs = 500;
  
  // Auto Refresh
  static const Duration defaultRefreshInterval = Duration(seconds: 30);
  static const Duration minRefreshInterval = Duration(seconds: 10);
  static const Duration maxRefreshInterval = Duration(minutes: 5);
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  
  // Log Levels
  static const String levelDebug = 'debug';
  static const String levelInfo = 'info';
  static const String levelWarn = 'warn';
  static const String levelError = 'error';
  
  // Status Code Ranges
  static const int statusSuccess = 200;
  static const int statusClientError = 400;
  static const int statusServerError = 500;
  
  // Time Ranges
  static const String rangeLastHour = 'last_hour';
  static const String rangeLast24Hours = 'last_24h';
  static const String rangeLast7Days = 'last_7d';
  static const String rangeLast30Days = 'last_30d';
  static const String rangeCustom = 'custom';
  
  // Date Formats
  static const String dateFormatFull = 'yyyy-MM-dd HH:mm:ss';
  static const String dateFormatShort = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm:ss';
  
  // Error Messages
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorUnauthorized = 'Invalid API key. Please check your settings.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorUnknown = 'An unexpected error occurred.';
  static const String errorNoData = 'No data available.';
  
  // Validation
  static const int minApiKeyLength = 10;
  static const int maxBodyPreviewLength = 1000;
}
