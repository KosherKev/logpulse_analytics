import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TimelineTab extends StatelessWidget {
  final LogEntry log;
  const TimelineTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (log.duration == null) {
      return Center(
        child: Text('No timeline data',
            style: AppTextStyles.body.copyWith(color: c.textTertiary)),
      );
    }

    final events = _generateEvents();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Total duration card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: c.accent, width: 3),
              top: BorderSide(color: c.border),
              right: BorderSide(color: c.border),
              bottom: BorderSide(color: c.border),
            ),
          ),
          child: Row(
            children: [
              Text('TOTAL',
                  style: AppTextStyles.label.copyWith(color: c.textTertiary)),
              const SizedBox(width: 14),
              Text(
                FormatUtils.formatDuration(log.duration!),
                style: AppTextStyles.h2.copyWith(color: c.textPrimary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Timeline events ──────────────────────────────────────────────
        Text('TIMELINE',
            style: AppTextStyles.label.copyWith(color: c.textTertiary)),
        const SizedBox(height: 14),

        ...events.asMap().entries.map((entry) {
          final i = entry.key;
          final ev = entry.value;
          return _TimelineEventRow(
            event: ev,
            isLast: i == events.length - 1,
            c: c,
          );
        }),

        const SizedBox(height: 20),

        // ── Performance breakdown ────────────────────────────────────────
        Text('PERFORMANCE BREAKDOWN',
            style: AppTextStyles.label.copyWith(color: c.textTertiary)),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              _BreakdownBar(
                label: 'Request Processing',
                percentage: 0.10,
                color: c.accent,
                duration: log.duration!,
                c: c,
              ),
              const SizedBox(height: 12),
              _BreakdownBar(
                label: 'Authentication',
                percentage: 0.05,
                color: c.success,
                duration: log.duration!,
                c: c,
              ),
              const SizedBox(height: 12),
              _BreakdownBar(
                label: 'Database Query',
                percentage: 0.70,
                color: c.warning,
                duration: log.duration!,
                c: c,
              ),
              const SizedBox(height: 12),
              _BreakdownBar(
                label: 'Response Generation',
                percentage: 0.15,
                color: c.info,
                duration: log.duration!,
                c: c,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_TimelineEvent> _generateEvents() {
    final total = log.duration ?? 0;
    return [
      _TimelineEvent(
        timestamp: '0ms',
        title: 'Request Received',
        detail: '${log.method ?? ''} ${log.path ?? ''}',
        isError: false,
      ),
      if (total > 10) ...[
        _TimelineEvent(
          timestamp: '5ms',
          title: 'Auth Validated',
          isError: false,
        ),
        _TimelineEvent(
          timestamp: '15ms',
          title: 'Request Validated',
          isError: false,
        ),
      ],
      if (log.error != null)
        _TimelineEvent(
          timestamp: '${(total * 0.8).round()}ms',
          title: log.error!.message ?? 'Error Occurred',
          detail: log.error!.code,
          isError: true,
        ),
      _TimelineEvent(
        timestamp: '${total}ms',
        title: 'Response Sent',
        detail: 'Status ${log.statusCode}',
        isError: false,
      ),
    ];
  }
}

// ── Timeline event row ────────────────────────────────────────────────────────

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    required this.event,
    required this.isLast,
    required this.c,
  });

  final _TimelineEvent event;
  final bool isLast;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    final dotColor = event.isError ? c.error : c.accent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dot + connector line column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: c.borderSoft,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Event content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.timestamp,
                        style: AppTextStyles.monoSm
                            .copyWith(color: c.textTertiary),
                      ),
                      if (event.isError) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.errorBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: c.error.withValues(alpha: 0.35)),
                          ),
                          child: Text('ERROR',
                              style: AppTextStyles.label
                                  .copyWith(color: c.error, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.title,
                    style: AppTextStyles.monoMd.copyWith(
                      color: event.isError ? c.error : c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.detail != null && event.detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.detail!,
                      style: AppTextStyles.monoSm
                          .copyWith(color: c.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown bar ─────────────────────────────────────────────────────────────

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.percentage,
    required this.color,
    required this.duration,
    required this.c,
  });

  final String label;
  final double percentage;
  final Color color;
  final int duration;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    final ms = (duration * percentage).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.monoSm.copyWith(color: c.textSecondary)),
            ),
            Text(
              '${FormatUtils.formatDuration(ms)} · ${(percentage * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar — themed colors, no hardcoded Flutter Colors
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                color: c.surface2,
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(height: 6, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _TimelineEvent {
  const _TimelineEvent({
    required this.timestamp,
    required this.title,
    this.detail,
    required this.isError,
  });

  final String timestamp;
  final String title;
  final String? detail;
  final bool isError;
}
