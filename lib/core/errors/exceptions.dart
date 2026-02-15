/// Custom exceptions for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  AppException(this.message, {this.code, this.details});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// API-related exceptions
class ApiException extends AppException {
  final int? statusCode;
  
  ApiException(
    super.message, {
    this.statusCode,
    super.code,
    super.details,
  });
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});
}

/// Cache-related exceptions
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.details});
}

/// Data parsing exceptions
class ParseException extends AppException {
  ParseException(super.message, {super.code, super.details});
}
