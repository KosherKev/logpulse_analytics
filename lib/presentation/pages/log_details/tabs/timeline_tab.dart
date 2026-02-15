import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';

/// Timeline Tab - Shows request processing timeline
class TimelineTab extends StatelessWidget {
  final LogEntry log;

  const TimelineTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    if (log.duration == null) {
      return const Center(
        child: Text('No timeline data available'),
      );
    }

    // Create mock timeline events (in real implementation, this would come from the log)
    final events = _generateTimelineEvents();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Duration Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Duration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 32, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      FormatUtils.formatDuration(log.duration!),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Timeline Visualization
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Timeline Events
        ...events.map((event) => _buildTimelineEvent(event)),

        const SizedBox(height: 24),

        // Performance Breakdown (if available)
        if (log.duration != null) _buildPerformanceBreakdown(),
      ],
    );
  }

  Widget _buildTimelineEvent(TimelineEvent event) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot and line
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.isError ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              if (!event.isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.timestamp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (event.isError)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ERROR',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: event.isError ? Colors.red : null,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildBreakdownItem('Request Processing', 0.1, Colors.blue),
            _buildBreakdownItem('Authentication', 0.05, Colors.green),
            _buildBreakdownItem('Database Query', 0.7, Colors.orange),
            _buildBreakdownItem('Response Generation', 0.15, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double percentage, Color color) {
    final duration = (log.duration! * percentage).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '${FormatUtils.formatDuration(duration)} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  List<TimelineEvent> _generateTimelineEvents() {
    // In real implementation, this would be parsed from the log data
    final events = <TimelineEvent>[];
    final totalDuration = log.duration ?? 0;

    events.add(TimelineEvent(
      timestamp: '0ms',
      title: 'Request Received',
      description: '${log.method} ${log.path}',
    ));

    if (totalDuration > 10) {
      events.add(TimelineEvent(
        timestamp: '5ms',
        title: 'Authentication Validated',
      ));

      events.add(TimelineEvent(
        timestamp: '15ms',
        title: 'Request Validated',
      ));
    }

    if (log.error != null) {
      events.add(TimelineEvent(
        timestamp: '${(totalDuration * 0.8).round()}ms',
        title: log.error!.message ?? 'Error Occurred',
        description: log.error!.code,
        isError: true,
      ));
    }

    events.add(TimelineEvent(
      timestamp: '${totalDuration}ms',
      title: 'Response Sent',
      description: 'Status: ${log.statusCode}',
      isLast: true,
    ));

    return events;
  }
}

/// Timeline Event Model
class TimelineEvent {
  final String timestamp;
  final String title;
  final String? description;
  final bool isError;
  final bool isLast;

  TimelineEvent({
    required this.timestamp,
    required this.title,
    this.description,
    this.isError = false,
    this.isLast = false,
  });
}
