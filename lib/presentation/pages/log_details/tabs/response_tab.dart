import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dart:convert';

/// Response Tab - Shows response headers and body
class ResponseTab extends StatefulWidget {
  final LogEntry log;

  const ResponseTab({super.key, required this.log});

  @override
  State<ResponseTab> createState() => _ResponseTabState();
}

class _ResponseTabState extends State<ResponseTab> {
  bool _prettyPrint = true;

  @override
  Widget build(BuildContext context) {
    if (widget.log.response == null) {
      return const Center(
        child: Text('No response data available'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.log.statusCode)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.log.statusCode != null
                            ? FormatUtils.formatStatusCode(
                                widget.log.statusCode!)
                            : 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(widget.log.statusCode),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Headers Section
        _buildExpandableSection(
          context,
          title: 'Headers',
          content: widget.log.response!.headers,
          defaultExpanded: false,
        ),
        const SizedBox(height: 16),

        // Body Section
        if (widget.log.response!.body != null) ...[
          _buildBodySection(
            context,
            title: 'Response Body',
            body: widget.log.response!.body,
          ),
        ] else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No response body'),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required String title,
    required Map<String, dynamic>? content,
    bool defaultExpanded = false,
  }) {
    if (content == null || content.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'No $title',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        initiallyExpanded: defaultExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          entry.key,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.value.toString(),
                          style: AppTextStyles.codeSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection(
    BuildContext context, {
    required String title,
    required dynamic body,
  }) {
    String bodyText;
    try {
      bodyText = _prettyPrint
          ? FormatUtils.prettyPrintJson(body)
          : json.encode(body);
    } catch (e) {
      bodyText = body.toString();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(bodyText),
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: Icon(
                    _prettyPrint ? Icons.code : Icons.wrap_text,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _prettyPrint = !_prettyPrint);
                  },
                  tooltip: _prettyPrint ? 'Raw' : 'Pretty',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(
              bodyText,
              style: AppTextStyles.codeSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return AppColors.border;
    if (statusCode >= 500) return AppColors.error;
    if (statusCode >= 400) return AppColors.warning;
    if (statusCode >= 200 && statusCode < 300) return AppColors.success;
    return AppColors.border;
  }
}
