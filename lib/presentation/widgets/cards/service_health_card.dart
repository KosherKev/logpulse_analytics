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
class ServiceHealthCard extends StatefulWidget {
  final String serviceName;
  final ServiceStats stats;
  final VoidCallback? onTap;

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

    _pulseController = AnimationController(vsync: this, duration: duration)
      ..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: healthColor, width: 2),
          top: BorderSide(color: c.border, width: 1),
          right: BorderSide(color: c.border, width: 1),
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Pulsing status dot
              AnimatedBuilder(
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
                              color: healthColor.withValues(alpha: 0.5),
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
              const SizedBox(width: 12),

              // Service name + detail row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: AppTextStyles.monoMd.copyWith(
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'err ${widget.stats.errorRate.toStringAsFixed(1)}%  ·  '
                      '${widget.stats.avgLatency.toStringAsFixed(0)}ms  ·  '
                      'up ${widget.stats.formattedUptime}',
                      style: AppTextStyles.monoSm.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Request count + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.stats.totalRequests}',
                    style: AppTextStyles.monoMd.copyWith(color: c.textPrimary),
                  ),
                  Text(
                    'req',
                    style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: c.textTertiary),
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
}
