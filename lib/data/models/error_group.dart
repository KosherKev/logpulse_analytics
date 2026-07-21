import 'log_entry.dart';

/// Error group model for grouping similar errors
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

  /// Representative trace from server groups API (deep-link to logs).
  final String? sampleTraceId;

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
    this.sampleTraceId,
  });

  /// CLS `GET /logs/errors/groups` row shape.
  factory ErrorGroup.fromApiJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v).toUtc();
        } catch (_) {}
      }
      return null;
    }

    int readInt(dynamic v, {int fallback = 0}) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final servicesRaw = json['services'];
    final services = <String>[];
    if (servicesRaw is List) {
      for (final s in servicesRaw) {
        if (s != null) services.add(s.toString());
      }
    }

    final trendRaw = (json['trend'] as String?)?.toLowerCase();
    TrendDirection trend = TrendDirection.stable;
    if (trendRaw == 'increasing') trend = TrendDirection.increasing;
    if (trendRaw == 'decreasing') trend = TrendDirection.decreasing;

    final first = parseDate(json['firstSeen'] ?? json['first_seen']) ??
        DateTime.now().toUtc();
    final last = parseDate(json['lastSeen'] ?? json['last_seen']) ?? first;

    return ErrorGroup(
      id: (json['id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      errorCode: json['errorCode']?.toString() ?? json['error_code']?.toString(),
      count: readInt(json['count']),
      services: services,
      firstSeen: first,
      lastSeen: last,
      stackTrace:
          json['sampleStack']?.toString() ?? json['stackTrace']?.toString(),
      sampleTraceId: json['sampleTraceId']?.toString() ??
          json['sample_trace_id']?.toString(),
      trend: trend,
    );
  }

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

  String get formattedServices {
    if (services.isEmpty) return 'Unknown';
    if (services.length == 1) return services.first;
    if (services.length == 2) return services.join(', ');
    return '${services.take(2).join(', ')}, +${services.length - 2} more';
  }
}

enum ErrorSeverity {
  critical,
  high,
  medium,
  low,
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
}
