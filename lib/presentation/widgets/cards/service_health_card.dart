import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/dashboard_stats.dart';

/// Neo-Terminal ServiceHealthCard.
///
/// Design:
///   - Left 2px border in health color (green / amber / red)
///   - Pulsing dot: slow 2s pulse for healthy, fast 0.8s for unhealthy
///   - Service name in JetBrains Mono 600
///   - Detail row: err% · latency · uptime in JetBrains Mono small textTertiary
///   - Optional custom-metrics chips (Phase 16) + instance badge (Phase 18)
class ServiceHealthCard extends StatefulWidget {
  final String serviceName;
  final ServiceStats stats;
  final VoidCallback? onTap;

  /// Max free-form metric chips before an overflow indicator is shown.
  static const int maxMetricChips = 4;

  const ServiceHealthCard({
    super.key,
    required this.serviceName,
    required this.stats,
    this.onTap,
  });

  @override
  State<ServiceHealthCard> createState() => _ServiceHealthCardState();
}

class _ServiceHealthCardState extends State<ServiceHealthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    final status = widget.stats.healthStatus;
    final duration = status == HealthStatus.unhealthy
        ? const Duration(milliseconds: 800)
        : const Duration(milliseconds: 2000);

    _pulseController = AnimationController(vsync: this, duration: duration);
    // Unknown (no metrics reported) gets a static dot, not a pulse — a pulse
    // implies a live health reading, which we don't have.
    if (status != HealthStatus.unknown) {
      _pulseController.repeat(reverse: true);
    }

    final maxOpacity = status == HealthStatus.unknown ? 0.5 : 1.0;
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.4, end: maxOpacity).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ServiceHealthCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats.healthStatus != widget.stats.healthStatus) {
      _pulseController.dispose();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final status = widget.stats.healthStatus;
    final healthColor = _healthColor(status, c);
    final showInstanceBadge =
        widget.stats.instanceCount != null && widget.stats.instanceCount! > 1;
    final showCustomMetrics = widget.stats.hasCustomMetrics;
    final lastReported = widget.stats.lastReportedAt;

    // Left health accent is a separate strip (not Border.left) so we can keep
    // borderRadius — Flutter forbids non-uniform border colors with radius.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2, color: healthColor),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pulsing status dot
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnim.value,
                              child: Opacity(
                                opacity: _opacityAnim.value,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: healthColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            healthColor.withValues(alpha: 0.5),
                                        blurRadius: 4 * _scaleAnim.value,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Service name + detail row + optional chips / relative time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.serviceName,
                                    style: AppTextStyles.monoMd.copyWith(
                                      color: c.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showInstanceBadge) ...[
                                  const SizedBox(width: 8),
                                  _InstanceBadge(
                                    count: widget.stats.instanceCount!,
                                    colors: c,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _detailLine(widget.stats),
                              style: AppTextStyles.monoSm.copyWith(
                                color: c.textTertiary,
                              ),
                            ),
                            if (lastReported != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _compactRelative(lastReported),
                                style: AppTextStyles.monoSm.copyWith(
                                  color: c.textTertiary,
                                ),
                              ),
                            ],
                            if (showCustomMetrics) ...[
                              const SizedBox(height: 8),
                              _CustomMetricsChips(
                                metrics: widget.stats.customMetrics!,
                                colors: c,
                                maxChips: ServiceHealthCard.maxMetricChips,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Request count + chevron
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.stats.totalRequests}',
                            style: AppTextStyles.monoMd
                                .copyWith(color: c.textPrimary),
                          ),
                          Text(
                            'req',
                            style: AppTextStyles.monoSm
                                .copyWith(color: c.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.chevron_right,
                            size: 18, color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _healthColor(HealthStatus status, AppColorTokens c) {
    switch (status) {
      case HealthStatus.healthy:
        return c.success;
      case HealthStatus.degraded:
        return c.warning;
      case HealthStatus.unhealthy:
        return c.error;
      default:
        return c.border;
    }
  }

  /// Detail line priority:
  /// 1. Log numerics (err% · latency) when [ServiceStats.hasHealthMetrics],
  ///    plus uptime % or uptime duration when available
  /// 2. Reported health status + duration when only PR-24 health exists
  /// 3. Honest "not reporting" when neither is present
  static String _detailLine(ServiceStats stats) {
    if (stats.hasHealthMetrics) {
      final parts = <String>[
        'err ${stats.errorRate!.toStringAsFixed(1)}%',
        '${stats.avgLatency!.toStringAsFixed(0)}ms',
      ];
      if (stats.uptime != null) {
        parts.add('up ${stats.formattedUptime}');
      } else if (stats.uptimeSeconds != null) {
        parts.add('up ${stats.formattedUptimeDuration}');
      }
      return parts.join('  ·  ');
    }
    if (stats.hasReportedHealth) {
      final status = stats.reportedHealthStatus!;
      if (stats.uptimeSeconds != null) {
        return '$status  ·  up ${stats.formattedUptimeDuration}';
      }
      return status;
    }
    return 'not reporting metrics yet';
  }

  /// Compact relative label: "2m ago", "3h ago", etc.
  static String _compactRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.isNegative || difference.inSeconds < 60) {
      return '${difference.isNegative ? 0 : difference.inSeconds}s ago';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}

class _InstanceBadge extends StatelessWidget {
  final int count;
  final AppColorTokens colors;

  const _InstanceBadge({required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        '$count instances',
        style: AppTextStyles.monoSm.copyWith(
          color: colors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CustomMetricsChips extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final AppColorTokens colors;
  final int maxChips;

  const _CustomMetricsChips({
    required this.metrics,
    required this.colors,
    required this.maxChips,
  });

  @override
  Widget build(BuildContext context) {
    final entries = metrics.entries.toList();
    final visible = entries.take(maxChips).toList();
    final overflow = entries.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final e in visible)
          _MetricChip(
            label: '${e.key}:${_stringifyValue(e.value)}',
            colors: colors,
          ),
        if (overflow > 0)
          _MetricChip(
            label: '+$overflow',
            colors: colors,
          ),
      ],
    );
  }

  /// Safely stringify nested / non-primitive metric values.
  static String _stringifyValue(dynamic value) {
    if (value == null) return '—';
    if (value is num || value is bool) return value.toString();
    if (value is String) return value;
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final AppColorTokens colors;

  const _MetricChip({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: colors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.monoSm.copyWith(
          color: colors.textSecondary,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
