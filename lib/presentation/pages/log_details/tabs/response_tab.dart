import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';
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
      padding: const EdgeInsets.all(16),
      children: [
        // Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.log.statusCode)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.log.statusCode != null
                            ? FormatUtils.formatStatusCode(
                                widget.log.statusCode!)
                            : 'Unknown',
                        style: TextStyle(
                          color: _getStatusColor(widget.log.statusCode),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

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
          padding: const EdgeInsets.all(16),
          child: Text('No $title'),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        initiallyExpanded: defaultExpanded,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          entry.value.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              bodyText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
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
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 500) return Colors.red;
    if (statusCode >= 400) return Colors.orange;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    return Colors.grey;
  }
}
