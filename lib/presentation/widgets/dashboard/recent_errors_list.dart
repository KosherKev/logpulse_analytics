import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/error_group.dart';

class RecentErrorsList extends StatelessWidget {
  final List<ErrorGroup> errorGroups;

  const RecentErrorsList({
    super.key,
    required this.errorGroups,
  });

  @override
  Widget build(BuildContext context) {
    if (errorGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    final recent = errorGroups.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Critical Errors',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recent.map((group) {
          final color = _severityColor(group.severity);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error, color: color, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${group.errorCode ?? ''} ${group.services.join(', ')}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    group.message,
                    style: AppTextStyles.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
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
