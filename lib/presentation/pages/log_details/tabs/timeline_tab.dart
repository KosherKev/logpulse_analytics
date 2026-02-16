import 'package:flutter/material.dart';
import '../../../../data/models/log_entry.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Timeline Tab - Shows request processing timeline
class TimelineTab extends StatelessWidget {
  final LogEntry log;

  const TimelineTab({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    if (log.duration == null) {
      return const Center(
        child: Text('No timeline data available'),
      );
    }

    // Create mock timeline events (in real implementation, this would come from the log)
    final events = _generateTimelineEvents();

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
                  'Request Duration',
                  style: AppTextStyles.h4.copyWith(
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 32,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      FormatUtils.formatDuration(log.duration!),
                      style: AppTextStyles.h2.copyWith(
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Timeline Visualization
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'Timeline',
            style: AppTextStyles.h4.copyWith(
              color: primaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Timeline Events
        ...events.map((event) => _buildTimelineEvent(event, secondaryTextColor,
            primaryTextColor)),

        const SizedBox(height: AppSpacing.lg),

        // Performance Breakdown (if available)
        if (log.duration != null)
          _buildPerformanceBreakdown(
            primaryTextColor,
            secondaryTextColor,
            isDark,
          ),
      ],
    );
  }

  Widget _buildTimelineEvent(
    TimelineEvent event,
    Color secondaryTextColor,
    Color primaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.md),
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
                  color: event.isError ? AppColors.error : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!event.isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: AppColors.border,
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
                      style: AppTextStyles.codeSmall.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (event.isError)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ERROR',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: event.isError ? AppColors.error : primaryTextColor,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: secondaryTextColor,
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

  Widget _buildPerformanceBreakdown(
    Color primaryTextColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Breakdown',
              style: AppTextStyles.h4.copyWith(
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildBreakdownItem(
              'Request Processing',
              0.1,
              Colors.blue,
              secondaryTextColor,
              isDark,
            ),
            _buildBreakdownItem(
              'Authentication',
              0.05,
              Colors.green,
              secondaryTextColor,
              isDark,
            ),
            _buildBreakdownItem(
              'Database Query',
              0.7,
              Colors.orange,
              secondaryTextColor,
              isDark,
            ),
            _buildBreakdownItem(
              'Response Generation',
              0.15,
              Colors.purple,
              secondaryTextColor,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    double percentage,
    Color color,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final duration = (log.duration! * percentage).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '${FormatUtils.formatDuration(duration)} (${(percentage * 100).toStringAsFixed(1)}%)',
                style: AppTextStyles.codeSmall.copyWith(
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
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
