import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Neo-Terminal StatCard.
///
/// Design:
///   - Left 3px accent border (color-coded by [accentColor])
///   - [label] in JetBrains Mono uppercase overline (textTertiary)
///   - [value] in Syne display bold
///   - Optional [delta] row in JetBrains Mono with directional color
///   - No elevation — border-only surface
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? accentColor;
  final String? delta;
  final bool? isPositive;

  // Legacy compat — icon ignored in new design but kept for call-site compat
  final IconData? icon;
  final Color? color;
  final String? trend;

  const StatCard({
    super.key,
    String? label,
    required this.value,
    this.accentColor,
    this.delta,
    this.isPositive,
    String? title,
    this.icon,
    this.color,
    this.trend,
  }) : label = label ?? title ?? '';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderColor = accentColor ?? color ?? c.accent;
    final effectiveDelta = delta ?? trend;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 3),
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
          if (effectiveDelta != null) ...[
            const SizedBox(height: 6),
            _DeltaRow(delta: effectiveDelta, isPositive: isPositive, c: c),
          ],
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.delta,
    required this.isPositive,
    required this.c,
  });

  final String delta;
  final bool? isPositive;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData? iconData;

    if (isPositive == null) {
      color = c.textTertiary;
      iconData = null;
    } else if (isPositive!) {
      color = c.success;
      iconData = Icons.arrow_upward_rounded;
    } else {
      color = c.error;
      iconData = Icons.arrow_downward_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconData != null) ...[
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 3),
        ],
        Text(
          delta,
          style: AppTextStyles.monoSm.copyWith(color: color),
        ),
      ],
    );
  }
}
