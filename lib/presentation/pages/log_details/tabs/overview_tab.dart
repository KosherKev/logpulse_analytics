import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../trace_logs_page.dart';
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

        if (log.isError) ...[
          const SizedBox(height: 12),
          DetailSection(
            title: 'ERROR SUMMARY',
            accentBorder: c.error,
            c: c,
            children: [
              if (log.displayError.isNotEmpty)
                DetailKVRow(
                  label: 'Message',
                  value: log.displayError,
                    valueColor: c.error,
                    c: c),
              if (log.error?.code != null)
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
                    builder: (_) => TraceLogsPage(traceId: log.traceId!),
                  ),
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

