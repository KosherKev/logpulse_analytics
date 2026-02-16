class TimeSeriesPoint {
  final DateTime timestamp;
  final int totalCount;
  final int errorCount;

  TimeSeriesPoint({
    required this.timestamp,
    required this.totalCount,
    required this.errorCount,
  });

  double get errorRatePercent {
    if (totalCount == 0) {
      return 0.0;
    }
    return (errorCount / totalCount) * 100.0;
  }
}

