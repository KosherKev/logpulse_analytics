import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/log_entry.dart';

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
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Errors',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('This log entry has no error information'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Error Details Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
        const SizedBox(height: 16),

        // Stack Trace Card
        if (log.error!.stack != null) ...[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Stack Trace',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[900],
                  child: SelectableText(
                    log.error!.stack!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Actions Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
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
