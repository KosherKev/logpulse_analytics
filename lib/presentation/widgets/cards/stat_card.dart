import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Neo-Terminal StatCard.
///
/// Design:
///   - Left 3px accent strip (color-coded by [accentColor])
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
        border: Border.all(color: c.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: borderColor),
            Expanded(
              child: Padding(
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
                      style: AppTextStyles.displaySm
                          .copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (effectiveDelta != null) ...[
                      const SizedBox(height: 6),
                      _DeltaRow(
                        delta: effectiveDelta,
                        isPositive: isPositive,
                        c: c,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final String delta;
  final bool? isPositive;
  final AppColorTokens c;

  const _DeltaRow({
    required this.delta,
    required this.isPositive,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    Color color = c.textTertiary;
    if (isPositive == true) color = c.success;
    if (isPositive == false) color = c.error;

    return Text(
      delta,
      style: AppTextStyles.monoSm.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
