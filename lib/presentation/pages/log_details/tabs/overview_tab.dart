import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../providers/logs_provider.dart';
import 'detail_widgets.dart';

class OverviewTab extends ConsumerWidget {
  final LogEntry log;
  const OverviewTab({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        DetailSection(
          title: 'REQUEST SUMMARY',
          c: c,
          children: [
            DetailKVRow(label: 'Method', value: log.method ?? 'N/A', c: c),
            DetailKVRow(label: 'Path', value: log.path ?? 'N/A', c: c),
            DetailKVRow(
              label: 'Status',
              value: log.statusCode?.toString() ?? 'N/A',
              valueColor: _statusColor(log.statusCode, c),
              c: c,
            ),
            DetailKVRow(
              label: 'Duration',
              value: log.duration != null
                  ? FormatUtils.formatDuration(log.duration!)
                  : 'N/A',
              c: c,
            ),
            DetailKVRow(
              label: 'Timestamp',
              value: date_utils.DateUtils.formatFull(log.timestamp),
              c: c,
            ),
            if (log.request?.ip != null)
              DetailKVRow(label: 'IP Address', value: log.request!.ip!, c: c),
          ],
        ),

        if (log.error != null) ...[
          const SizedBox(height: 12),
          DetailSection(
            title: 'ERROR SUMMARY',
            accentBorder: c.error,
            c: c,
            children: [
              if (log.error!.message != null)
                DetailKVRow(
                    label: 'Message',
                    value: log.error!.message!,
                    valueColor: c.error,
                    c: c),
              if (log.error!.code != null)
                DetailKVRow(label: 'Code', value: log.error!.code!, c: c),
            ],
          ),
        ],

        if (log.traceId != null) ...[
          const SizedBox(height: 12),
          DetailSection(
            title: 'TRACE',
            c: c,
            children: [
              DetailKVRow(
                label: 'Trace ID',
                value: log.traceId!,
                valueColor: c.accent,
                c: c,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _TraceLogsPage(traceId: log.traceId!)),
                ),
                icon: Icon(Icons.account_tree_rounded, size: 16, color: c.accent),
                label: Text('View Related Logs',
                    style: AppTextStyles.bodySmall.copyWith(color: c.accent)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],

        if (log.metadata != null && log.metadata!.isNotEmpty) ...[
          const SizedBox(height: 12),
          DetailSection(
            title: 'METADATA',
            c: c,
            children: log.metadata!.entries
                .map((e) =>
                    DetailKVRow(label: e.key, value: e.value.toString(), c: c))
                .toList(),
          ),
        ],
      ],
    );
  }

  Color _statusColor(int? code, AppColorTokens c) {
    if (code == null) return c.textPrimary;
    if (code >= 500) return c.error;
    if (code >= 400) return c.warning;
    if (code >= 200 && code < 300) return c.success;
    return c.textPrimary;
  }
}

// ── Trace logs viewer ─────────────────────────────────────────────────────────

class _TraceLogsPage extends ConsumerWidget {
  final String traceId;
  const _TraceLogsPage({required this.traceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final logsAsync = ref.watch(logsByTraceIdProvider(traceId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text('Trace Logs',
            style: AppTextStyles.h3.copyWith(color: c.textPrimary)),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Failed to load: $e',
                style: AppTextStyles.body.copyWith(color: c.error))),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
                child: Text('No logs for this trace',
                    style:
                        AppTextStyles.body.copyWith(color: c.textTertiary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final entry = logs[index];
              final levelColor = c.levelColor(entry.level);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: levelColor, width: 3),
                    top: BorderSide(color: c.border),
                    right: BorderSide(color: c.border),
                    bottom: BorderSide(color: c.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(entry.level.toUpperCase(),
                          style: AppTextStyles.label
                              .copyWith(color: levelColor)),
                      const SizedBox(width: 8),
                      Text(entry.service,
                          style: AppTextStyles.monoSm
                              .copyWith(color: c.textPrimary)),
                    ]),
                    const SizedBox(height: 4),
                    Text(date_utils.DateUtils.formatFull(entry.timestamp),
                        style: AppTextStyles.monoSm
                            .copyWith(color: c.textTertiary)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
