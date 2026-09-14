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
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: c.accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Text('TOTAL',
                            style: AppTextStyles.label
                                .copyWith(color: c.textTertiary)),
                        const SizedBox(width: 14),
                        Text(
                          FormatUtils.formatDuration(log.duration!),
                          style:
                              AppTextStyles.h2.copyWith(color: c.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
      ],
    );
  }

  // NOTE: this tab previously also rendered a "PERFORMANCE BREAKDOWN" section
  // (fixed 10/5/70/15% stage split applied to log.duration) and two synthetic
  // mid-timeline events ("Auth Validated" @ 5ms, "Request Validated" @ 15ms,
  // and an error event at total*0.8ms). None of these have a backing field —
  // the backend has no per-stage timing data. Per the 2026-06-17 log entry's
  // own conclusion ("fabricated percentages... are worse than showing
  // nothing"), these were removed rather than kept as confident-looking fake
  // numbers. Only real fields are shown below: method/path, duration,
  // statusCode, and (when present) the error itself — without inventing a
  // timestamp for it.

  List<_TimelineEvent> _generateEvents() {
    final total = log.duration ?? 0;
    return [
      _TimelineEvent(
        timestamp: '0ms',
        title: 'Request Received',
        detail: '${log.method ?? ''} ${log.path ?? ''}',
        isError: false,
      ),
      if (log.isError)
        _TimelineEvent(
          // No real per-stage timestamp exists for when the error occurred
          // within the request lifecycle — show it unordered by time rather
          // than inventing one.
          timestamp: null,
          title: log.displayError,
          detail: log.error?.code,
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
                        event.timestamp ?? '—',
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
                      style:
                          AppTextStyles.monoSm.copyWith(color: c.textTertiary),
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

// ── Model ─────────────────────────────────────────────────────────────────────

class _TimelineEvent {
  const _TimelineEvent({
    required this.timestamp,
    required this.title,
    this.detail,
    required this.isError,
  });

  /// Null when no real timestamp is known for this event (e.g. an error
  /// with no per-stage timing data) — shown as an em dash rather than a
  /// made-up value.
  final String? timestamp;
  final String title;
  final String? detail;
  final bool isError;
}
