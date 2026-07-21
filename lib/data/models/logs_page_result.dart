import 'log_entry.dart';

/// Result of a paginated logs fetch, including optional server-side total.
class LogsPageResult {
  final List<LogEntry> logs;

  /// Total matching documents from the collector (`total` / `pagination.total`).
  /// Null when the response was a bare list (legacy).
  final int? total;

  /// Server `pagination.hasMore` when present.
  final bool? hasMore;

  const LogsPageResult({
    required this.logs,
    this.total,
    this.hasMore,
  });
}
