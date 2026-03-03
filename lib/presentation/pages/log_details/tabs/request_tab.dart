import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'detail_widgets.dart';

class RequestTab extends StatefulWidget {
  final LogEntry log;
  const RequestTab({super.key, required this.log});

  @override
  State<RequestTab> createState() => _RequestTabState();
}

class _RequestTabState extends State<RequestTab> {
  bool _prettyPrint = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (widget.log.request == null) {
      return Center(
          child: Text('No request data',
              style: AppTextStyles.body.copyWith(color: c.textTertiary)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        DetailHeadersSection(
          title: 'REQUEST HEADERS',
          content: widget.log.request!.headers,
          c: c,
        ),
        const SizedBox(height: 12),
        DetailHeadersSection(
          title: 'QUERY PARAMS',
          content: widget.log.request!.query,
          c: c,
        ),
        const SizedBox(height: 12),
        if (widget.log.request!.body != null)
          DetailBodySection(
            title: 'REQUEST BODY',
            body: widget.log.request!.body,
            prettyPrint: _prettyPrint,
            onTogglePretty: () =>
                setState(() => _prettyPrint = !_prettyPrint),
            c: c,
          )
        else
          DetailEmptyBlock(label: 'No request body', c: c),
      ],
    );
  }
}
