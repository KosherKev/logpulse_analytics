import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../providers/logs_provider.dart';

/// All logs sharing a [traceId] (Overview + Error tab actions).
class TraceLogsPage extends ConsumerWidget {
  final String traceId;

  const TraceLogsPage({super.key, required this.traceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final logsAsync = ref.watch(logsByTraceIdProvider(traceId));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(
          'Trace Logs',
          style: AppTextStyles.h3.copyWith(color: c.textPrimary),
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load: $e',
            style: AppTextStyles.body.copyWith(color: c.error),
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(
                'No logs for this trace',
                style: AppTextStyles.body.copyWith(color: c.textTertiary),
              ),
            );
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
                  border: Border.all(color: c.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 3, color: levelColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.level.toUpperCase(),
                                    style: AppTextStyles.label
                                        .copyWith(color: levelColor),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.service,
                                      style: AppTextStyles.monoSm
                                          .copyWith(color: c.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (entry.method != null &&
                                  entry.path != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.method} ${entry.path}',
                                  style: AppTextStyles.monoSm
                                      .copyWith(color: c.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                date_utils.DateUtils.formatFull(
                                    entry.timestamp),
                                style: AppTextStyles.monoSm
                                    .copyWith(color: c.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
