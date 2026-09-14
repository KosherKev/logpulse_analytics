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

  /// Authoritative status code from the server's `GET /logs/errors/groups`
  /// response (`sampleStatusCode`, added in CLS `39de821`), derived there from
  /// the sample log's real `statusCode` field. Prefer this over
  /// [inferredStatusCode]'s client-side guess whenever present.
  final int? sampleStatusCode;

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
    this.sampleStatusCode,
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

    int? readNullableInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
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
      errorCode:
          json['errorCode']?.toString() ?? json['error_code']?.toString(),
      count: readInt(json['count']),
      services: services,
      firstSeen: first,
      lastSeen: last,
      stackTrace:
          json['sampleStack']?.toString() ?? json['stackTrace']?.toString(),
      sampleTraceId: json['sampleTraceId']?.toString() ??
          json['sample_trace_id']?.toString(),
      sampleStatusCode: readNullableInt(
          json['sampleStatusCode'] ?? json['sample_status_code']),
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

  /// HTTP status for this group. Prefers the server's authoritative
  /// [sampleStatusCode] (CLS `39de821`+); falls back to a client-side guess
  /// from [instances]/code/message for older server responses that predate it.
  int? get inferredStatusCode {
    if (sampleStatusCode != null) return sampleStatusCode;

    final fromInstances = instances
        ?.map((i) => i.statusCode)
        .whereType<int>()
        .where((s) => s >= 400 && s < 600)
        .toList();
    if (fromInstances != null && fromInstances.isNotEmpty) {
      final fiveXx = fromInstances.where((s) => s >= 500);
      if (fiveXx.isNotEmpty) return fiveXx.first;
      return fromInstances.first;
    }

    final code = errorCode?.trim();
    if (code != null && code.isNotEmpty) {
      final n = int.tryParse(code);
      if (n != null && n >= 400 && n < 600) return n;
    }

    final httpMatch = RegExp(
      r'(?:HTTP\s+|status(?:Code)?[:\s]+)([45]\d{2})\b',
      caseSensitive: false,
    ).firstMatch(message);
    if (httpMatch != null) {
      return int.tryParse(httpMatch.group(1)!);
    }

    final bare = RegExp(r'^([45]\d{2})\b').firstMatch(message.trim());
    if (bare != null) return int.tryParse(bare.group(1)!);

    return null;
  }

  /// True when this group is clearly a client HTTP error (4xx).
  bool get isClientErrorGroup {
    final status = inferredStatusCode;
    if (status != null) return status >= 400 && status < 500;

    if (instances != null && instances!.isNotEmpty) {
      final has4xx = instances!.any((i) => i.isClientError);
      final has5xx = instances!.any((i) => i.isServerError);
      return has4xx && !has5xx;
    }

    return false;
  }

  /// Server / application errors. Default when not clearly 4xx so summary
  /// cards stay meaningful for CLS groups that lack status codes.
  bool get isServerErrorGroup => !isClientErrorGroup;
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
