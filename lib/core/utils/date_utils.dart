import 'package:intl/intl.dart';

/// Date and time formatting utilities
class DateUtils {
  /// Format datetime to full format: "2026-02-14 10:30:45"
  static String formatFull(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
  
  /// Format datetime to short format: "Feb 14, 2026"
  static String formatShort(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }
  
  /// Format time only: "10:30:45"
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
  
  /// Format datetime to relative time: "2 minutes ago"
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
  
  /// Parse ISO 8601 string to DateTime
  static DateTime? parseIso8601(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  
  /// Get start and end dates for time range
  static (DateTime start, DateTime end) getTimeRange(String range) {
    final now = DateTime.now();
    
    switch (range) {
      case 'last_hour':
        return (now.subtract(const Duration(hours: 1)), now);
      case 'last_24h':
        return (now.subtract(const Duration(hours: 24)), now);
      case 'last_7d':
        return (now.subtract(const Duration(days: 7)), now);
      case 'last_30d':
        return (now.subtract(const Duration(days: 30)), now);
      default:
        return (now.subtract(const Duration(hours: 24)), now);
    }
  }
  
  /// Convert DateTime to ISO 8601 string
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
}
