import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/format_utils.dart';
import '../../../data/models/log_entry.dart';

/// Neo-Terminal EnhancedLogCard.
///
/// Design:
///   - Left 3px border in log-level color
///   - Level chip: JetBrains Mono uppercase, colored bg+border
///   - Service name: JetBrains Mono 600
///   - Method + path row: accent method, mono path on surface2 bg
///   - Meta row: icon-text pairs (timestamp / duration / traceId)
///   - Error preview pill at bottom when log.error?.message != null
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
    final c = AppColors.of(context);
    final levelColor = c.levelColor(log.level);
    final levelBg = c.levelBg(log.level);
    final statusColor = _statusColor(log.statusCode, c);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: levelColor, width: 3),
          top: BorderSide(color: c.border, width: 1),
          right: BorderSide(color: c.border, width: 1),
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Level chip · Service name · Status code ──────
              Row(
                children: [
                  _LevelChip(
                    level: log.level,
                    color: levelColor,
                    bg: levelBg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.service,
                      style: AppTextStyles.monoMd.copyWith(
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (log.statusCode != null) ...[
                    const SizedBox(width: 8),
                    _StatusBadge(
                      code: log.statusCode!,
                      color: statusColor,
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 16, color: c.textTertiary),
                ],
              ),

              // ── Row 2: Method + path ─────────────────────────────────
              if (log.method != null && log.path != null) ...[
                const SizedBox(height: 8),
                _MethodPathRow(
                  method: log.method!,
                  path: log.path!,
                  c: c,
                ),
              ],

              // ── Row 3: Meta (timestamp · duration · traceId) ─────────
              const SizedBox(height: 8),
              _MetaRow(log: log, c: c),

              // ── Row 4: Error preview pill ─────────────────────────────
              if (log.error?.message != null) ...[
                const SizedBox(height: 8),
                _ErrorPill(message: log.error!.message!, c: c),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(int? code, AppColorTokens c) {
    if (code == null) return c.border;
    if (code >= 500) return c.error;
    if (code >= 400) return c.warning;
    if (code >= 200 && code < 300) return c.success;
    return c.border;
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.level,
    required this.color,
    required this.bg,
  });

  final String level;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        level.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.code, required this.color});

  final int code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$code',
        style: AppTextStyles.monoSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MethodPathRow extends StatelessWidget {
  const _MethodPathRow({
    required this.method,
    required this.path,
    required this.c,
  });

  final String method;
  final String path;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            method,
            style: AppTextStyles.monoSm.copyWith(
              color: c.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              style: AppTextStyles.monoSm.copyWith(color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.log, required this.c});

  final LogEntry log;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule, size: 12, color: c.textTertiary),
        const SizedBox(width: 3),
        Text(
          date_utils.DateUtils.formatRelative(log.timestamp),
          style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
        ),
        if (log.duration != null) ...[
          _dot(c),
          Icon(Icons.speed, size: 12, color: c.textTertiary),
          const SizedBox(width: 3),
          Text(
            FormatUtils.formatDuration(log.duration!),
            style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
          ),
        ],
        if (log.traceId != null) ...[
          _dot(c),
          Icon(Icons.timeline, size: 12, color: c.textTertiary),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              log.traceId!,
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dot(AppColorTokens c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text('·', style: TextStyle(color: c.textTertiary, fontSize: 11)),
      );
}

class _ErrorPill extends StatelessWidget {
  const _ErrorPill({required this.message, required this.c});

  final String message;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        message,
        style: AppTextStyles.monoSm.copyWith(color: c.error),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
