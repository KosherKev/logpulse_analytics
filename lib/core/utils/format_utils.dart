import 'dart:convert';

/// Formatting utilities
class FormatUtils {
  /// Format duration in milliseconds to human-readable string
  static String formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    } else if (milliseconds < 60000) {
      final seconds = (milliseconds / 1000).toStringAsFixed(2);
      return '${seconds}s';
    } else {
      final minutes = (milliseconds / 60000).floor();
      final seconds = ((milliseconds % 60000) / 1000).floor();
      return '${minutes}m ${seconds}s';
    }
  }

  /// Format bytes to human-readable size
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1048576) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    }
  }

  /// Format number with thousand separators
  static String formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Pretty print JSON
  static String prettyPrintJson(dynamic json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      // If the value is already a String, it may be a serialized JSON body
      // (common when backends log response.body as a string). Attempt to decode
      // it first so we pretty-print the parsed structure, not a JSON-of-a-string.
      if (json is String) {
        try {
          final decoded = jsonDecode(json);
          return encoder.convert(decoded);
        } catch (_) {
          // Not valid JSON — return the raw string as-is
          return json;
        }
      }
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  /// Truncate string with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Extract domain from URL
  static String? extractDomain(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Format HTTP status code with text
  static String formatStatusCode(int statusCode) {
    final statusText = _getStatusText(statusCode);
    return '$statusCode $statusText';
  }

  static String _getStatusText(int code) {
    if (code >= 200 && code < 300) return 'Success';
    if (code >= 300 && code < 400) return 'Redirect';
    if (code >= 400 && code < 500) return 'Client Error';
    if (code >= 500) return 'Server Error';
    return 'Unknown';
  }
}
