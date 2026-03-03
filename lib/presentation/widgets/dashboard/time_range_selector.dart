import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Compact pill-style time range selector matching the mockup.
/// Values: last_hour → 1h, last_24h → 24h, last_7d → 7d, last_30d → 30d
class TimeRangeSelector extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  static const _options = [
    ('last_hour', '1h'),
    ('last_24h', '24h'),
    ('last_7d', '7d'),
    ('last_30d', '30d'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: _options.map((opt) {
        final (value, label) = opt;
        final selected = value == selectedRange;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onRangeChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? c.accent : c.border,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.monoSm.copyWith(
                  color: selected ? Colors.white : c.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
