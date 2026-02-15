import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/errors_provider.dart';
import '../../../data/models/error_group.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/errors/summary_card.dart';
import '../../widgets/errors/error_group_card.dart';

/// Errors Page - Error tracking and grouping
class ErrorsPage extends ConsumerStatefulWidget {
  const ErrorsPage({super.key});

  @override
  ConsumerState<ErrorsPage> createState() => _ErrorsPageState();
}

class _ErrorsPageState extends ConsumerState<ErrorsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(errorsProvider.notifier).loadErrors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorsState = ref.watch(errorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(errorsProvider.notifier).loadErrors();
            },
          ),
        ],
      ),
      body: _buildBody(errorsState),
    );
  }

  Widget _buildBody(ErrorsState state) {
    if (state.isLoading && state.errorGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.errorGroups.isEmpty) {
      return _buildError(state.error!);
    }

    if (state.errorGroups.isEmpty) {
      return _buildEmpty();
    }

    final totalGroups = state.errorGroups.length;
    final serverGroups = state.errorGroups
        .where(
          (g) =>
              g.instances?.any(
                (i) => i.statusCode != null && i.statusCode! >= 500,
              ) ??
              false,
        )
        .length;
    final clientGroups = state.errorGroups
        .where(
          (g) =>
              g.instances?.any(
                (i) =>
                    i.statusCode != null &&
                    i.statusCode! >= 400 &&
                    i.statusCode! < 500,
              ) ??
              false,
        )
        .length;

    return RefreshIndicator(
      onRefresh: () => ref.read(errorsProvider.notifier).loadErrors(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: ErrorSummaryCard(
                  label: 'Total Error Groups',
                  value: totalGroups.toString(),
                  icon: Icons.error_outline,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ErrorSummaryCard(
                  label: '5xx Groups',
                  value: serverGroups.toString(),
                  icon: Icons.cloud_off,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ErrorSummaryCard(
            label: '4xx Groups',
            value: clientGroups.toString(),
            icon: Icons.report_problem,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Error Groups',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...state.errorGroups.map(
            (group) => ErrorGroupCard(
              group: group,
              onTap: () => _showErrorDetails(group),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDetails(ErrorGroup group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Details',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              group.message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Occurrences: ${group.count}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'First seen: ${date_utils.DateUtils.formatRelative(group.firstSeen)}',
              style: AppTextStyles.caption,
            ),
            Text(
              'Last seen: ${date_utils.DateUtils.formatRelative(group.lastSeen)}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Affected Services',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...group.services.map(
              (s) => Text(
                '• $s',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
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
            'Error Loading Errors',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Errors Found',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All systems running smoothly!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
