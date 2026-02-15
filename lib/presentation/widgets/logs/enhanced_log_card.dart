import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/format_utils.dart';
import '../../../data/models/log_entry.dart';

class EnhancedLogCard extends StatelessWidget {
  final LogEntry log;
  final VoidCallback onTap;

  const EnhancedLogCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(log.level);
    final statusColor = _getStatusColor(log.statusCode);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: levelColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getLevelIcon(log.level), size: 14, color: levelColor),
                        const SizedBox(width: 4),
                        Text(
                          log.level.toUpperCase(),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      log.service,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (log.statusCode != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log.statusCode.toString(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (log.method != null && log.path != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        log.method!,
                        style: AppTextStyles.codeSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.path!,
                          style: AppTextStyles.codeSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    date_utils.DateUtils.formatRelative(log.timestamp),
                    style: AppTextStyles.caption,
                  ),
                  if (log.duration != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.speed, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      FormatUtils.formatDuration(log.duration!),
                      style: AppTextStyles.caption,
                    ),
                  ],
                  if (log.traceId != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.timeline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.traceId!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (log.error?.message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  log.error!.message!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return AppColors.error;
      case 'warn':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      case 'debug':
        return AppColors.debug;
      default:
        return AppColors.border;
    }
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return AppColors.border;
    if (statusCode >= 500) return AppColors.error;
    if (statusCode >= 400) return AppColors.warning;
    if (statusCode >= 200 && statusCode < 300) return AppColors.success;
    return AppColors.border;
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warn':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      case 'debug':
        return Icons.bug_report;
      default:
        return Icons.circle;
    }
  }
}
