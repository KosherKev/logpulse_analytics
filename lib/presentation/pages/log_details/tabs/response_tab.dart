import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'detail_widgets.dart';

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
    final c = AppColors.of(context);

    if (widget.log.response == null) {
      return Center(
          child: Text('No response data',
              style: AppTextStyles.body.copyWith(color: c.textTertiary)));
    }

    final statusColor = _statusColor(widget.log.statusCode, c);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Status card — left-border coloured by status
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
              top: BorderSide(color: c.border),
              right: BorderSide(color: c.border),
              bottom: BorderSide(color: c.border),
            ),
          ),
          child: Row(
            children: [
              Text('STATUS',
                  style: AppTextStyles.label.copyWith(color: c.textTertiary)),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.log.statusCode != null
                      ? FormatUtils.formatStatusCode(widget.log.statusCode!)
                      : 'Unknown',
                  style: AppTextStyles.monoMd.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        DetailHeadersSection(
          title: 'RESPONSE HEADERS',
          content: widget.log.response!.headers,
          c: c,
        ),
        const SizedBox(height: 12),

        if (widget.log.response!.body != null)
          DetailBodySection(
            title: 'RESPONSE BODY',
            body: widget.log.response!.body,
            prettyPrint: _prettyPrint,
            onTogglePretty: () =>
                setState(() => _prettyPrint = !_prettyPrint),
            c: c,
          )
        else
          DetailEmptyBlock(label: 'No response body', c: c),
      ],
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
