import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ── Dual-axis scale helpers (unit-tested independently of fl_chart) ─────────

/// Minimum percentage-point range for the error axis so a steady ~0.3% rate
/// is not stretched full-height (looks artificially volatile).
/// TODO: revisit once real telemetry gives a sense of typical error-rate
/// distributions (same pattern as health-status vocabulary mapping).
const double kErrorAxisFloorPercent = 5.0;

/// Round [value] up to a "nice" axis maximum (1 / 1.5 / 2 / 3 / 5 × 10ⁿ)
/// so tick labels don't read as 109 / 43% next to near-duplicates.
double niceCeilMax(double value) {
  if (value <= 0) return 1.0;
  final magnitude =
      math.pow(10, (math.log(value) / math.ln10).floor()).toDouble();
  final residual = value / magnitude;
  final double niceResidual;
  if (residual <= 1) {
    niceResidual = 1;
  } else if (residual <= 1.5) {
    niceResidual = 1.5;
  } else if (residual <= 2) {
    niceResidual = 2;
  } else if (residual <= 3) {
    niceResidual = 3;
  } else if (residual <= 5) {
    niceResidual = 5;
  } else {
    niceResidual = 10;
  }
  return niceResidual * magnitude;
}

/// Host (traffic count) axis max with headroom, nice-rounded. Never zero.
double computeTrafficMaxY(List<FlSpot> traffic) {
  if (traffic.isEmpty) return 1.0;
  final peak = traffic.map((p) => p.y).reduce(math.max);
  final withHeadroom = peak * 1.25;
  if (withHeadroom <= 0) return 1.0;
  return niceCeilMax(withHeadroom);
}

/// True error-rate (%) axis max with floor, 100% clamp, nice-rounded.
double computeErrorMaxY(List<FlSpot> errors) {
  if (errors.isEmpty) return kErrorAxisFloorPercent;
  final peak = errors.map((p) => p.y).reduce(math.max);
  final withHeadroom = peak * 1.25;
  final floored = math.max(withHeadroom, kErrorAxisFloorPercent);
  final capped = math.min(floored, 100.0);
  final nice = niceCeilMax(capped);
  return math.min(nice, 100.0).clamp(kErrorAxisFloorPercent, 100.0);
}

/// Exactly three host-Y tick anchors: 0, mid, top — snapped to [interval]
/// so fl_chart actually emits them, without stacking two near-max labels.
List<double> axisTickHosts(double maxY, double interval) {
  if (maxY <= 0) return const [0];
  final step = interval <= 0 ? maxY : interval;
  final mid = ((maxY / 2) / step).round() * step;
  // Last grid step at or below max — single top label (avoids 100 + 109).
  var top = (maxY / step).floor() * step;
  if (top <= 0) top = maxY;
  // If mid lands on 0 or top, drop it.
  final ticks = <double>{0, top};
  if (mid > step * 0.25 && (top - mid).abs() > step * 0.25) {
    ticks.add(mid);
  }
  return ticks.toList()..sort();
}

bool isAxisTick(double value, double maxY, double interval) {
  if (value < -1e-6 || value > maxY + 1e-6) return false;
  final hosts = axisTickHosts(maxY, interval);
  final tol = math.max(interval * 0.05, 1e-6);
  for (final t in hosts) {
    if ((value - t).abs() <= tol) return true;
  }
  return false;
}

/// Project true error % into the traffic (host) coordinate space for plotting.
List<FlSpot> transformErrorPointsForPlot(
  List<FlSpot> trueErrors, {
  required double errorMaxY,
  required double trafficMaxY,
}) {
  assert(errorMaxY > 0);
  return trueErrors
      .map((p) => FlSpot(p.x, (p.y / errorMaxY) * trafficMaxY))
      .toList();
}

/// Lookup true error % by bucket x (matches transformed spots' x).
double? trueErrorValueAtX(List<FlSpot> trueErrors, double x) {
  for (final p in trueErrors) {
    if ((p.x - x).abs() < 1e-9) return p.y;
  }
  // Nearest x as fallback
  if (trueErrors.isEmpty) return null;
  FlSpot best = trueErrors.first;
  var bestDist = (best.x - x).abs();
  for (final p in trueErrors) {
    final d = (p.x - x).abs();
    if (d < bestDist) {
      best = p;
      bestDist = d;
    }
  }
  return best.y;
}

/// Dual-line "Traffic & Errors" chart.
///
/// Traffic plots in native count units (host Y-axis). Error rate is rescaled
/// into that host space for drawing only (fake dual Y-axis); tooltips use true
/// percentages. Left ticks = counts; right ticks = %.
///
/// Legacy single-series API ([points] + [label] + [lineColor] + [areaColor])
/// is preserved and does not use the dual-axis transform.
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
    final trueErrors = errorPoints ?? const <FlSpot>[];
    final isDualSeries = trafficPoints != null || errorPoints != null;
    final isLegacyOnly = !isDualSeries && points != null && points!.isNotEmpty;

    // Colours
    final trafficColor = c.accent;
    final errorColor = c.error;

    // ── Axis ranges ────────────────────────────────────────────────────────
    final trafficMaxY = computeTrafficMaxY(
      trafficPoints != null ? traffic : (isLegacyOnly ? points! : traffic),
    );
    final errorMaxY = computeErrorMaxY(trueErrors);

    // Host maxY for LineChartData — dual uses traffic host; legacy uses own peak.
    final double hostMaxY;
    if (isDualSeries) {
      hostMaxY = trafficMaxY;
    } else if (isLegacyOnly) {
      final peak = points!.map((p) => p.y).reduce(math.max) * 1.25;
      hostMaxY = peak <= 0 ? 1.0 : peak;
    } else {
      hostMaxY = 1.0;
    }

    final interval = _interval(hostMaxY);

    // Transform errors for plot only; keep trueErrors for tooltips / right axis.
    final plottedErrors = isDualSeries && trueErrors.isNotEmpty
        ? transformErrorPointsForPlot(
            trueErrors,
            errorMaxY: errorMaxY,
            trafficMaxY: trafficMaxY,
          )
        : const <FlSpot>[];

    final hasPlotData = isDualSeries
        ? (traffic.isNotEmpty || trueErrors.isNotEmpty)
        : (points != null && points!.isNotEmpty);

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
          SizedBox(
            height: 160,
            child: !hasPlotData
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
                      maxY: hostMaxY,
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
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (!isAxisTick(value, hostMaxY, interval)) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Text(
                                  formatCountTick(value),
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: c.textTertiary,
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: isDualSeries && trueErrors.isNotEmpty,
                            reservedSize: 34,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (!isAxisTick(value, hostMaxY, interval)) {
                                return const SizedBox.shrink();
                              }
                              // Map host Y → true error % scale.
                              final frac = hostMaxY > 0
                                  ? (value / hostMaxY).clamp(0.0, 1.0)
                                  : 0.0;
                              final errPct = frac * errorMaxY;
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  formatPercentTick(errPct),
                                  style: AppTextStyles.monoSm.copyWith(
                                    color: c.textTertiary,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => c.surface2,
                          tooltipBorder: BorderSide(color: c.border),
                          getTooltipItems: (touchedSpots) {
                            final hasTrafficBar =
                                isDualSeries && traffic.isNotEmpty;
                            return touchedSpots.map((spot) {
                              final isTraffic = hasTrafficBar
                                  ? spot.barIndex == 0
                                  : (!isDualSeries);
                              final isErrorRate = isDualSeries &&
                                  ((hasTrafficBar && spot.barIndex == 1) ||
                                      (!hasTrafficBar &&
                                          trueErrors.isNotEmpty &&
                                          spot.barIndex == 0));

                              final String text;
                              if (isTraffic && isDualSeries) {
                                text = spot.y.round().toString();
                              } else if (isErrorRate) {
                                // True % — not transformed plot y.
                                final trueVal = trueErrorValueAtX(
                                      trueErrors,
                                      spot.x,
                                    ) ??
                                    0.0;
                                text = '${trueVal.toStringAsFixed(1)}%';
                              } else {
                                // Legacy single series.
                                text = spot.y == spot.y.roundToDouble()
                                    ? spot.y.round().toString()
                                    : spot.y.toStringAsFixed(1);
                              }

                              return LineTooltipItem(
                                text,
                                AppTextStyles.monoSm.copyWith(
                                  color: spot.bar.color ?? c.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        if (isDualSeries && traffic.isNotEmpty)
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
                                  trafficColor.withValues(
                                    alpha: isDark ? 0.25 : 0.15,
                                  ),
                                  trafficColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        if (isDualSeries && plottedErrors.isNotEmpty)
                          LineChartBarData(
                            spots: plottedErrors,
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
                        if (!isDualSeries &&
                            points != null &&
                            points!.isNotEmpty)
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
          if (isDualSeries) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                  color: trafficColor,
                  label: 'traffic',
                  dashed: false,
                ),
                const SizedBox(width: 16),
                _LegendDot(
                  color: errorColor,
                  label: 'errors %',
                  dashed: true,
                ),
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

/// Count tick label (left axis).
String formatCountTick(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    return k == k.roundToDouble()
        ? '${k.round()}k'
        : '${k.toStringAsFixed(1)}k';
  }
  return value.round().toString();
}

/// Percent tick label (right axis) — `0%` not `0.0%`.
String formatPercentTick(double value) {
  if (value.abs() < 1e-9) return '0%';
  if (value >= 10 || value == value.roundToDouble()) {
    return '${value.round()}%';
  }
  return '${value.toStringAsFixed(1)}%';
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
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    } else {
      double x = 0;
      const dash = 4.0;
      const gap = 3.0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset(math.min(x + dash, size.width), size.height / 2),
          paint,
        );
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.dashed != dashed;
}
