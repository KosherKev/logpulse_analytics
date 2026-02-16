import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ErrorRateChart extends StatelessWidget {
  final List<FlSpot> points;
  final String label;
  final Color lineColor;
  final Color areaColor;

  const ErrorRateChart({
    super.key,
    required this.points,
    this.label = 'Error Rate',
    Color? lineColor,
    Color? areaColor,
  })  : lineColor = lineColor ?? AppColors.error,
        areaColor = areaColor ?? AppColors.error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final maxY = points.isEmpty
        ? 0.0
        : points
            .map((p) => p.y)
            .reduce((a, b) => math.max(a, b));
    final effectiveMaxY = maxY == 0 ? 1.0 : maxY * 1.2;
    final interval = _calculateInterval(effectiveMaxY);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: points.isEmpty
                  ? Center(
                      child: Text(
                        'No chart data available',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: effectiveMaxY,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: interval,
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: interval,
                              getTitlesWidget: (value, meta) {
                                if (value < 0 ||
                                    value > effectiveMaxY + 0.0001) {
                                  return const SizedBox.shrink();
                                }

                                final rounded = value.round();
                                if (rounded % interval.round() != 0) {
                                  return const SizedBox.shrink();
                                }

                                return Text(
                                  rounded.toString(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: axisTextColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points,
                            isCurved: true,
                            color: lineColor,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: areaColor,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    return (maxY / 5).ceilToDouble();
  }
}
