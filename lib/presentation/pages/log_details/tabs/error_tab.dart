import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Error Tab - Shows error details and stack trace
class ErrorTab extends StatelessWidget {
  final LogEntry log;

  const ErrorTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    if (log.error == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            SizedBox(height: AppSpacing.md),
            Text(
              'No Errors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text('This log entry has no error information'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Details',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (log.error!.message != null) ...[
                  _buildInfoRow('Message', log.error!.message!),
                  const SizedBox(height: 8),
                ],
                if (log.error!.code != null) ...[
                  _buildInfoRow('Code', log.error!.code!),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Level', log.level.toUpperCase()),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (log.error!.stack != null) ...[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Text(
                        'Stack Trace',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => _copyToClipboard(
                          context,
                          log.error!.stack!,
                        ),
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.darkSurface,
                  child: SelectableText(
                    log.error!.stack!,
                    style: AppTextStyles.codeSmall.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // View similar errors
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('View Similar Errors'),
                ),
                const SizedBox(height: 8),
                if (log.traceId != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      // View related logs
                    },
                    icon: const Icon(Icons.timeline),
                    label: const Text('View Related Logs'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Stack trace copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
