import 'package:json_annotation/json_annotation.dart';

part 'log_entry.g.dart';

/// Log entry model
@JsonSerializable()
class LogEntry {
  final String? id;
  final DateTime timestamp;
  final String level;
  final String service;
  final String? traceId;
  final String? method;
  final String? path;
  final int? statusCode;
  final int? duration;
  final RequestData? request;
  final ResponseData? response;
  final ErrorData? error;
  final Map<String, dynamic>? metadata;
  
  LogEntry({
    this.id,
    required this.timestamp,
    required this.level,
    required this.service,
    this.traceId,
    this.method,
    this.path,
    this.statusCode,
    this.duration,
    this.request,
    this.response,
    this.error,
    this.metadata,
  });
  
  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LogEntryToJson(this);
  
  /// Check if this is an error log
  bool get isError => level == 'error' || (statusCode != null && statusCode! >= 400);
  
  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;
  
  /// Check if this is a client error (4xx)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  
  /// Get status category (success, client_error, server_error)
  String get statusCategory {
    if (statusCode == null) return 'unknown';
    if (statusCode! >= 500) return 'server_error';
    if (statusCode! >= 400) return 'client_error';
    if (statusCode! >= 200 && statusCode! < 300) return 'success';
    return 'other';
  }
}

/// Request data model
@JsonSerializable()
class RequestData {
  final Map<String, dynamic>? headers;
  final dynamic body;
  final Map<String, dynamic>? query;
  final String? ip;
  
  RequestData({
    this.headers,
    this.body,
    this.query,
    this.ip,
  });
  
  factory RequestData.fromJson(Map<String, dynamic> json) => _$RequestDataFromJson(json);
  Map<String, dynamic> toJson() => _$RequestDataToJson(this);
}

/// Response data model
@JsonSerializable()
class ResponseData {
  final dynamic body;
  final Map<String, dynamic>? headers;
  
  ResponseData({
    this.body,
    this.headers,
  });
  
  factory ResponseData.fromJson(Map<String, dynamic> json) => _$ResponseDataFromJson(json);
  Map<String, dynamic> toJson() => _$ResponseDataToJson(this);
}

/// Error data model
@JsonSerializable()
class ErrorData {
  final String? message;
  final String? stack;
  final String? code;
  
  ErrorData({
    this.message,
    this.stack,
    this.code,
  });
  
  factory ErrorData.fromJson(Map<String, dynamic> json) => _$ErrorDataFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorDataToJson(this);
}
