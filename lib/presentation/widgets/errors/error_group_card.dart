import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/error_group.dart';

/// Neo-Terminal ErrorGroupCard.
///
/// Design:
///   - Left 3px border in severity color
///   - Error code in JetBrains Mono label style
///   - Message in Inter bodyLarge
///   - Count badge and trend chip on right
///   - Last seen in JetBrains Mono monoSm
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
    final c = AppColors.of(context);
    final severityColor = _severityColor(group.severity, c);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: severityColor, width: 3),
          top: BorderSide(color: c.border, width: 1),
          right: BorderSide(color: c.border, width: 1),
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: code · message · count ───────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (group.errorCode != null)
                          Text(
                            group.errorCode!,
                            style: AppTextStyles.label.copyWith(
                              color: severityColor,
                            ),
                          ),
                        if (group.errorCode != null)
                          const SizedBox(height: 4),
                        Text(
                          group.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: c.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Count badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${group.count}',
                          style: AppTextStyles.monoSm.copyWith(
                            color: severityColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _TrendChip(trend: group.trend, c: c),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Row 2: services · last seen ──────────────────────────
              Row(
                children: [
                  Icon(Icons.dns_outlined, size: 12, color: c.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.formattedServices,
                      style: AppTextStyles.monoSm.copyWith(
                        color: c.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.access_time, size: 12, color: c.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    date_utils.DateUtils.formatRelative(group.lastSeen),
                    style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(ErrorSeverity severity, AppColorTokens c) {
    switch (severity) {
      case ErrorSeverity.critical:
        return c.error;
      case ErrorSeverity.high:
        return c.warning;
      case ErrorSeverity.medium:
        return c.info;
      case ErrorSeverity.low:
        return c.debug;
    }
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend, required this.c});

  final TrendDirection trend;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    if (trend == TrendDirection.stable) {
      return Text(
        'STABLE',
        style: AppTextStyles.label.copyWith(color: c.textTertiary),
      );
    }

    final isUp = trend == TrendDirection.increasing;
    final color = isUp ? c.error : c.success;
    final icon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          isUp ? 'RISING' : 'FALLING',
          style: AppTextStyles.label.copyWith(color: color),
        ),
      ],
    );
  }
}
