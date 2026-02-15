import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/dashboard_stats.dart';

/// Service Health Card - Shows service status with health indicator
class ServiceHealthCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final healthStatus = stats.healthStatus;
    final healthColor = _getHealthColor(healthStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Error Rate: ${stats.errorRate.toStringAsFixed(1)}% • '
                      'Uptime: ${stats.formattedUptime}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              // Stats badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.totalRequests}',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'requests',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHealthColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return AppColors.success;
      case HealthStatus.degraded:
        return AppColors.warning;
      case HealthStatus.unhealthy:
        return AppColors.error;
      default:
        return AppColors.border;
    }
  }
}
