import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'detail_widgets.dart';

class ErrorTab extends StatelessWidget {
  final LogEntry log;
  const ErrorTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (log.error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: c.success),
            const SizedBox(height: 14),
            Text('No Errors',
                style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
            const SizedBox(height: 8),
            Text('This log entry has no error information',
                style: AppTextStyles.body.copyWith(color: c.textTertiary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Error details
        DetailSection(
          title: 'ERROR DETAILS',
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
            DetailKVRow(
                label: 'Level',
                value: log.level.toUpperCase(),
                valueColor: c.levelColor(log.level),
                c: c),
          ],
        ),

        // Stack trace — dark terminal container
        if (log.error!.stack != null) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Row(
                    children: [
                      Text('STACK TRACE',
                          style: AppTextStyles.label
                              .copyWith(color: c.textTertiary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: log.error!.stack!));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Stack trace copied',
                                style: AppTextStyles.monoSm),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.copy_rounded,
                              size: 16, color: c.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.borderSoft),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    ),
                  ),
                  child: SelectableText(
                    log.error!.stack!,
                    style: AppTextStyles.monoSm.copyWith(
                      color: AppColors.darkTextPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Actions
        const SizedBox(height: 12),
        DetailSection(
          title: 'ACTIONS',
          c: c,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.search, size: 16, color: c.accent),
                    label: Text('View Similar',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: c.accent)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: c.accent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (log.traceId != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.timeline, size: 16, color: c.accent),
                      label: Text('Trace Logs',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: c.accent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: c.accent.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
