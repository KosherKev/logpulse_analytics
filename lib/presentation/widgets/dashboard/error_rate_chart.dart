import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Dual-line "Traffic & Errors" chart matching the mockup.
///
/// Shows two series on one chart:
///   - [trafficPoints] — solid blue line with gradient fill
///   - [errorPoints]   — dashed red line with faint fill
///
/// Legacy single-series API ([points] + [label] + [lineColor] + [areaColor])
/// is preserved so existing call sites compile unchanged.
class ErrorRateChart extends StatelessWidget {
  // ── Dual-series API (Phase 9) ──────────────────────────────────────────────
  final List<FlSpot>? trafficPoints;
  final List<FlSpot>? errorPoints;

  // ── Legacy single-series API ───────────────────────────────────────────────
  final List<FlSpot>? points;
  final String? label;
  final Color? lineColor;
  final Color? areaColor;

  /// "last 24h · 1h buckets" — subtitle shown top-right
  final String? subtitle;

  const ErrorRateChart({
    super.key,
    // Dual-series
    this.trafficPoints,
    this.errorPoints,
    this.subtitle,
    // Legacy
    this.points,
    this.label,
    this.lineColor,
    this.areaColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve which series to use
    final traffic = trafficPoints ?? points ?? [];
    final errors = errorPoints ?? [];
    final isDualSeries = trafficPoints != null || errorPoints != null;

    // Colours
    final trafficColor = c.accent;
    final errorColor = c.error;

    // Y-axis range — unified across both series
    final allPoints = [...traffic, ...errors];
    final maxY = allPoints.isEmpty
        ? 1.0
        : allPoints.map((p) => p.y).reduce(math.max) * 1.25;
    final effectiveMaxY = maxY == 0 ? 1.0 : maxY;
    final interval = _interval(effectiveMaxY);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(
            children: [
              Text(
                isDualSeries ? 'Traffic & Errors' : (label ?? 'Chart'),
                style: AppTextStyles.h3.copyWith(color: c.textPrimary),
              ),
              const Spacer(),
              Text(
                subtitle ?? _defaultSubtitle(),
                style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chart ────────────────────────────────────────────────────────────
          SizedBox(
            height: 160,
            child: allPoints.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: effectiveMaxY,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: c.borderSoft,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        // Traffic — solid with gradient fill
                        if (traffic.isNotEmpty)
                          LineChartBarData(
                            spots: traffic,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: trafficColor,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  trafficColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                  trafficColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        // Errors — dashed red line with faint fill
                        if (errors.isNotEmpty)
                          LineChartBarData(
                            spots: errors,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: errorColor,
                            barWidth: 1.5,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: errorColor.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                            ),
                          ),
                        // Legacy single-series fallback
                        if (traffic.isEmpty && errors.isEmpty && points != null)
                          LineChartBarData(
                            spots: points!,
                            isCurved: true,
                            color: lineColor ?? c.accent,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: (areaColor ?? c.accent)
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // ── Legend ───────────────────────────────────────────────────────────
          if (isDualSeries) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(color: trafficColor, label: 'traffic', dashed: false),
                const SizedBox(width: 16),
                _LegendDot(color: errorColor, label: 'errors', dashed: true),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _defaultSubtitle() => 'last 24h · 1h buckets';

  double _interval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    return (maxY / 5).ceilToDouble();
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.dashed,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Small line swatch
        SizedBox(
          width: 20,
          height: 2,
          child: CustomPaint(
            painter: _LinePainter(color: color, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (!dashed) {
      canvas.drawLine(Offset(0, size.height / 2),
          Offset(size.width, size.height / 2), paint);
    } else {
      double x = 0;
      const dash = 4.0;
      const gap = 3.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, size.height / 2),
            Offset(math.min(x + dash, size.width), size.height / 2), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.dashed != dashed;
}
