import 'package:dio/dio.dart';
import 'package:logger/logger.dart' hide LogFilter;
import '../models/log_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/log_filter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';

/// API service for communicating with the central logging service
class ApiService {
  final Dio _dio;
  final Logger _logger = Logger();
  
  String? _baseUrl;
  String? _apiKey;
  
  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _configureDio();
  }
  
  void _configureDio() {
    _dio.options.connectTimeout = AppConstants.connectionTimeout;
    _dio.options.receiveTimeout = AppConstants.apiTimeout;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add interceptors for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }
  
  /// Configure API with base URL and API key
  void configure({required String baseUrl, required String apiKey}) {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    
    _dio.options.baseUrl = '$baseUrl${AppConstants.apiBasePath}';
    _dio.options.headers['X-API-Key'] = apiKey;
  }
  
  /// Check if API is configured
  bool get isConfigured => _baseUrl != null && _apiKey != null;
  
  /// Fetch logs with filters
  Future<List<LogEntry>> getLogs(LogFilter filter) async {
    try {
      _ensureConfigured();
      
      final endpoint = ApiEndpoints.buildLogsQuery(
        service: filter.service,
        level: filter.level,
        statusCode: filter.statusCode,
        after: filter.startDate?.toIso8601String(),
        before: filter.endDate?.toIso8601String(),
        limit: filter.limit,
        offset: filter.offset,
        search: filter.searchQuery,
      );
      
      final response = await _dio.get(endpoint);
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LogEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      throw ParseException('Invalid response format');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch log by ID
  Future<LogEntry> getLogById(String id) async {
    try {
      _ensureConfigured();
      
      final response = await _dio.get(ApiEndpoints.logById(id));
      return LogEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch logs by trace ID
  Future<List<LogEntry>> getLogsByTraceId(String traceId) async {
    try {
      _ensureConfigured();
      
      final response = await _dio.get(ApiEndpoints.logsByTraceId(traceId));
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LogEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      throw ParseException('Invalid response format');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch dashboard statistics
  Future<DashboardStats> getDashboardStats({String? timeRange}) async {
    try {
      _ensureConfigured();
      
      final endpoint = ApiEndpoints.buildStatsQuery(timeRange: timeRange);
      final response = await _dio.get(endpoint);
      
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Check service health
  Future<bool> checkHealth() async {
    try {
      _ensureConfigured();
      
      final response = await _dio.get(ApiEndpoints.health);
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logger.w('Health check failed: ${e.message}');
      return false;
    }
  }
  
  void _ensureConfigured() {
    if (!isConfigured) {
      throw AuthException('API not configured. Please set base URL and API key.');
    }
  }
  
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          AppConstants.errorNetwork,
          code: 'TIMEOUT',
          details: error.message,
        );
        
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        
        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            AppConstants.errorUnauthorized,
            code: 'UNAUTHORIZED',
            details: error.response?.data,
          );
        }
        
        if (statusCode != null && statusCode >= 500) {
          return ApiException(
            AppConstants.errorServerError,
            statusCode: statusCode,
            details: error.response?.data,
          );
        }
        
        return ApiException(
          error.response?.data?['message'] ?? AppConstants.errorUnknown,
          statusCode: statusCode,
          details: error.response?.data,
        );
        
      case DioExceptionType.cancel:
        return NetworkException(
          'Request cancelled',
          code: 'CANCELLED',
        );
        
      default:
        return NetworkException(
          error.message ?? AppConstants.errorNetwork,
          code: 'NETWORK_ERROR',
          details: error,
        );
    }
  }
}
