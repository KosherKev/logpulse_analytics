import 'package:dio/dio.dart';
import 'package:logger/logger.dart' hide LogFilter;
import '../models/log_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/log_filter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';

class ApiService {
  final Dio _dio;
  final Logger _logger = Logger();

  String? _baseUrl;
  String? _apiKey;

  ApiService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = AppConstants.connectionTimeout
      ..receiveTimeout = AppConstants.apiTimeout
      ..headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('Request: ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
            'Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'Error (${error.type}): ${error.message ?? error.error}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  void configure({required String baseUrl, String? apiKey}) {
    final normalizedBaseUrl =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    _baseUrl = normalizedBaseUrl;

    final trimmedKey = apiKey?.trim();
    if (trimmedKey != null && trimmedKey.isNotEmpty) {
      _apiKey = trimmedKey;
      _dio.options.headers['X-API-Key'] = trimmedKey;
    } else {
      _apiKey = null;
      _dio.options.headers.remove('X-API-Key');
    }
  }

  bool get isConfigured => _baseUrl != null && _baseUrl!.isNotEmpty;

  String get _apiRoot => '$_baseUrl${AppConstants.apiBasePath}';
  
  /// Fetch logs with filters
  Future<List<LogEntry>> getLogs(LogFilter filter) async {
    try {
      _ensureConfigured();

      final endpoint = ApiEndpoints.buildLogsQuery(
        service: filter.service,
        level: filter.level,
        statusCode: filter.statusCode,
        from: filter.startDate?.toIso8601String(),
        to: filter.endDate?.toIso8601String(),
        limit: filter.limit,
        offset: filter.offset,
        search: filter.searchQuery,
      );

      final response = await _dio.get('$_apiRoot$endpoint');
      final body = response.data;

      List<dynamic>? items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic> && body['data'] is List) {
        items = body['data'] as List<dynamic>;
      }

      if (items == null) {
        throw ParseException('Invalid response format for logs');
      }

      return items.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        map['id'] ??= map['_id']?.toString();
        return LogEntry.fromJson(map);
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Fetch logs by trace ID
  Future<List<LogEntry>> getLogsByTraceId(String traceId) async {
    try {
      _ensureConfigured();

      final endpoint = ApiEndpoints.logsByTraceId(traceId);
      final response = await _dio.get('$_apiRoot$endpoint');
      final body = response.data;

      List<dynamic>? items;
      if (body is List) {
        items = body;
      } else if (body is Map<String, dynamic> && body['data'] is List) {
        items = body['data'] as List<dynamic>;
      }

      if (items == null) {
        throw ParseException('Invalid response format for logs by trace ID');
      }

      return items.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        map['id'] ??= map['_id']?.toString();
        return LogEntry.fromJson(map);
      }).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _extractErrorMessage(Response? response, String fallback) {
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    }

    return fallback;
  }
  
  /// Fetch dashboard statistics
  Future<DashboardStats> getDashboardStats({String? timeRange}) async {
    try {
      _ensureConfigured();

      final endpoint = ApiEndpoints.buildStatsQuery(timeRange: timeRange);
      final response = await _dio.get('$_apiRoot$endpoint');

      return DashboardStats.fromApiJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  /// Check service health
  Future<bool> checkHealth() async {
    try {
      _ensureConfigured();

      final endpoint = ApiEndpoints.health;
      final response = await _dio.get('$_apiRoot$endpoint');
      return response.statusCode == 200;
    } on DioException catch (e) {
      _logger.w('Health check failed: ${e.message}');
      return false;
    }
  }
  
  void _ensureConfigured() {
    if (!isConfigured) {
      throw AuthException('API not configured. Please set base URL in Settings.');
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
        final response = error.response;
        final statusCode = response?.statusCode;
        final backendMessage =
            _extractErrorMessage(response, AppConstants.errorUnknown);

        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            'HTTP $statusCode: $backendMessage',
            code: 'UNAUTHORIZED',
            details: response?.data,
          );
        }

        if (statusCode != null && statusCode >= 500) {
          return ApiException(
            'HTTP $statusCode: $backendMessage',
            statusCode: statusCode,
            details: response?.data,
          );
        }

        return ApiException(
          statusCode != null
              ? 'HTTP $statusCode: $backendMessage'
              : backendMessage,
          statusCode: statusCode,
          details: response?.data,
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
