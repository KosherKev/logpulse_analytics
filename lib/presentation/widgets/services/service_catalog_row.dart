import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/service_summary.dart';

/// Compact catalog row for [ServicesPage] — not [ServiceHealthCard]
/// ([ServiceStats] shape is different).
class ServiceCatalogRow extends StatelessWidget {
  final ServiceSummary service;
  final VoidCallback onTap;

  const ServiceCatalogRow({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final status = ServiceStats.healthFromErrorRate(service.errorRate);
    final statusColor = _statusColor(status, c);
    final showInstances =
        service.instanceCount != null && service.instanceCount! > 1;

    final errLabel = service.errorRate == null
        ? '—'
        : '${service.errorRate!.toStringAsFixed(1)}%';
    final latLabel = service.avgLatency == null
        ? '—'
        : '${service.avgLatency!.toStringAsFixed(0)}ms';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: statusColor),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    service.label,
                                    style: AppTextStyles.monoMd
                                        .copyWith(color: c.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (showInstances) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surface2,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Text(
                                      '${service.instanceCount} instances',
                                      style: AppTextStyles.monoSm.copyWith(
                                        color: c.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'err $errLabel  ·  $latLabel'
                              '${service.lastSeen != null ? '  ·  ${date_utils.DateUtils.formatCompactRelative(service.lastSeen!)}' : ''}',
                              style: AppTextStyles.monoSm
                                  .copyWith(color: c.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${service.totalRequests}',
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
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: c.textTertiary),
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

  Color _statusColor(HealthStatus status, AppColorTokens c) {
    switch (status) {
      case HealthStatus.healthy:
        return c.success;
      case HealthStatus.degraded:
        return c.warning;
      case HealthStatus.unhealthy:
        return c.error;
      case HealthStatus.unknown:
        return c.border;
    }
  }
}
