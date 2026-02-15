import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/error_group.dart';

class ErrorGroupCard extends StatelessWidget {
  final ErrorGroup group;
  final VoidCallback onTap;

  const ErrorGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = _severityColor(group.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 32,
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (group.errorCode != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: Text(
                                  group.errorCode!,
                                  style: AppTextStyles.codeSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                group.message,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Services: ${group.formattedServices}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${group.count}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildTrendChip(group.trend, severityColor),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last: ${date_utils.DateUtils.formatRelative(group.lastSeen)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChip(TrendDirection trend, Color severityColor) {
    if (trend == TrendDirection.stable) {
      return Text(
        'Stable',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final isIncreasing = trend == TrendDirection.increasing;
    final icon = isIncreasing ? Icons.trending_up : Icons.trending_down;
    final color = isIncreasing ? AppColors.error : AppColors.success;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          isIncreasing ? 'Rising' : 'Falling',
          style: AppTextStyles.caption.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Color _severityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return AppColors.error;
      case ErrorSeverity.high:
        return AppColors.warning;
      case ErrorSeverity.medium:
        return AppColors.info;
      case ErrorSeverity.low:
        return AppColors.debug;
    }
  }
}
