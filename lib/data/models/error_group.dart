import 'package:json_annotation/json_annotation.dart';
import 'log_entry.dart';

part 'error_group.g.dart';

/// Error group model for grouping similar errors
@JsonSerializable()
class ErrorGroup {
  final String id;
  final String message;
  final String? errorCode;
  final int count;
  final List<String> services;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String? stackTrace;
  final bool isResolved;
  final TrendDirection trend;
  final List<LogEntry>? instances;
  
  ErrorGroup({
    required this.id,
    required this.message,
    this.errorCode,
    required this.count,
    required this.services,
    required this.firstSeen,
    required this.lastSeen,
    this.stackTrace,
    this.isResolved = false,
    this.trend = TrendDirection.stable,
    this.instances,
  });
  
  factory ErrorGroup.fromJson(Map<String, dynamic> json) => _$ErrorGroupFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorGroupToJson(this);
  
  /// Get severity based on count and recency
  ErrorSeverity get severity {
    final hoursSinceLastSeen = DateTime.now().difference(lastSeen).inHours;
    
    if (count > 50 && hoursSinceLastSeen < 1) {
      return ErrorSeverity.critical;
    } else if (count > 20 && hoursSinceLastSeen < 6) {
      return ErrorSeverity.high;
    } else if (count > 5) {
      return ErrorSeverity.medium;
    } else {
      return ErrorSeverity.low;
    }
  }
  
  /// Get formatted service list
  String get formattedServices {
    if (services.isEmpty) return 'Unknown';
    if (services.length == 1) return services.first;
    if (services.length == 2) return services.join(', ');
    return '${services.take(2).join(', ')}, +${services.length - 2} more';
  }
}

/// Error severity levels
enum ErrorSeverity {
  critical,
  high,
  medium,
  low,
}

/// Trend direction for errors
enum TrendDirection {
  increasing,
  decreasing,
  stable,
}
