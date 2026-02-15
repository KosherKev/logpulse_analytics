import 'package:flutter/material.dart';
import '../../../data/models/log_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/format_utils.dart';
import 'tabs/overview_tab.dart';
import 'tabs/request_tab.dart';
import 'tabs/response_tab.dart';
import 'tabs/error_tab.dart';
import 'tabs/timeline_tab.dart';

/// Log Details Page with 5 tabs
class LogDetailsPage extends StatefulWidget {
  final LogEntry log;

  const LogDetailsPage({
    super.key,
    required this.log,
  });

  @override
  State<LogDetailsPage> createState() => _LogDetailsPageState();
}

class _LogDetailsPageState extends State<LogDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: _buildContent(log),
    );
  }

  Widget _buildContent(LogEntry log) {
    return Column(
      children: [
        _buildHeader(log),
        Material(
          color: AppColors.surface,
          elevation: 2,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
              Tab(text: 'Error'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              OverviewTab(log: log),
              RequestTab(log: log),
              ResponseTab(log: log),
              ErrorTab(log: log),
              TimelineTab(log: log),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(LogEntry log) {
    final levelColor = _getLevelColor(log.level);
    final statusColor = _getStatusColor(log.statusCode);

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.level.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: levelColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    log.service,
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (log.statusCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.statusCode.toString(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (log.method != null && log.path != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      log.method!,
                      style: AppTextStyles.codeSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        log.path!,
                        style: AppTextStyles.codeSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  date_utils.DateUtils.formatFull(log.timestamp),
                  style: AppTextStyles.caption,
                ),
                if (log.duration != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    FormatUtils.formatDuration(log.duration!),
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
            if (log.traceId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.fingerprint,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Trace: ${log.traceId}',
                      style: AppTextStyles.codeSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      // Copy trace ID
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to Load Log',
            style: AppTextStyles.h3.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return AppColors.error;
      case 'warn':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      case 'debug':
        return AppColors.debug;
      default:
        return AppColors.border;
    }
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return AppColors.border;
    if (statusCode >= 500) return AppColors.error;
    if (statusCode >= 400) return AppColors.warning;
    if (statusCode >= 200 && statusCode < 300) return AppColors.success;
    return AppColors.border;
  }
}
