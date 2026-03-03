import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Neo-Terminal ErrorSummaryCard.
///
/// Design:
///   - Left 3px border in [color]
///   - [label] in JetBrains Mono label uppercase (textTertiary)
///   - [value] in Syne displaySm
///   - No icon — border color conveys the category
class ErrorSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Legacy compat — icon ignored in new design
  final IconData? icon;

  const ErrorSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
          top: BorderSide(color: c.border, width: 1),
          right: BorderSide(color: c.border, width: 1),
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: c.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.displaySm.copyWith(color: c.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
