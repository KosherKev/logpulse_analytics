import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TimeRangeSelector extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildChip('last_hour', 'Last Hour'),
              _buildChip('last_24h', 'Last 24h'),
              _buildChip('last_7d', 'Last 7 Days'),
              _buildChip('last_30d', 'Last 30 Days'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String value, String label) {
    final selected = value == selectedRange;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: selected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceVariant,
        onSelected: (isSelected) {
          if (isSelected) {
            onRangeChanged(value);
          }
        },
      ),
    );
  }
}
