import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Overview Tab - Summary of the log entry
class OverviewTab extends StatelessWidget {
  final LogEntry log;

  const OverviewTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSection(
          context,
          title: 'Request Summary',
          children: [
            _buildInfoRow('Method', log.method ?? 'N/A'),
            _buildInfoRow('Path', log.path ?? 'N/A'),
            _buildInfoRow('Status Code', log.statusCode?.toString() ?? 'N/A'),
            _buildInfoRow(
              'Duration',
              log.duration != null
                  ? FormatUtils.formatDuration(log.duration!)
                  : 'N/A',
            ),
            _buildInfoRow(
              'Timestamp',
              date_utils.DateUtils.formatFull(log.timestamp),
            ),
            if (log.request?.ip != null)
              _buildInfoRow('IP Address', log.request!.ip!),
          ],
        ),
        const SizedBox(height: 16),
        if (log.error != null) ...[
          _buildSection(
            context,
            title: 'Error Summary',
            children: [
              _buildInfoRow('Message', log.error!.message ?? 'N/A'),
              if (log.error!.code != null)
                _buildInfoRow('Code', log.error!.code!),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (log.traceId != null) ...[
          _buildSection(
            context,
            title: 'Trace Information',
            children: [
              _buildInfoRow('Trace ID', log.traceId!),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to related logs
                },
                icon: const Icon(Icons.search),
                label: const Text('View Related Logs'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (log.metadata != null && log.metadata!.isNotEmpty) ...[
          _buildSection(
            context,
            title: 'Metadata',
            children: log.metadata!.entries.map((entry) {
              return _buildInfoRow(
                entry.key,
                entry.value.toString(),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: AppTextStyles.codeSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
