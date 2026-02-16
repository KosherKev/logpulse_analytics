import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/logs_provider.dart';
import '../../../data/models/log_filter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/saved_filters_provider.dart';
import '../../providers/service_providers.dart';
import '../log_details/log_details_page.dart';
import '../../widgets/logs/enhanced_log_card.dart';

/// Logs Page
class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(logsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ApiConfigState>(apiConfigProvider, (previous, next) {
      final wasConfigured = previous?.isConfigured ?? false;
      if (!wasConfigured && next.isConfigured) {
        ref.read(logsProvider.notifier).loadLogs(refresh: true);
      }
    });

    final logsState = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
      ),
      body: _buildBody(logsState),
      floatingActionButton: logsState.logs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  Widget _buildBody(LogsState state) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.logs.isEmpty) {
      return _buildError(state.error!);
    }

    if (state.logs.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(logsProvider.notifier).loadLogs(refresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLevelFilterChips(state),
                  const SizedBox(height: AppSpacing.sm),
                  _buildActiveFiltersRow(state),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == state.logs.length) {
                  if (!state.hasMore) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final log = state.logs[index];
                return EnhancedLogCard(
                  log: log,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LogDetailsPage(log: log),
                      ),
                    );
                  },
                );
              },
              childCount: state.logs.length + (state.hasMore ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search logs, trace IDs, messages...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () {
                _showSavedFiltersSheet();
              },
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(logsProvider.notifier).clearFilter();
                },
              ),
          ],
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          ref.read(logsProvider.notifier).search(value);
        }
      },
    );
  }

  Widget _buildLevelFilterChips(LogsState state) {
    final currentLevel = state.filter.level;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLevelChip('All', null, currentLevel),
          const SizedBox(width: AppSpacing.xs),
          _buildLevelChip('Error', AppConstants.levelError, currentLevel),
          const SizedBox(width: AppSpacing.xs),
          _buildLevelChip('Warn', AppConstants.levelWarn, currentLevel),
          const SizedBox(width: AppSpacing.xs),
          _buildLevelChip('Info', AppConstants.levelInfo, currentLevel),
          const SizedBox(width: AppSpacing.xs),
          _buildLevelChip('Debug', AppConstants.levelDebug, currentLevel),
        ],
      ),
    );
  }

  Widget _buildLevelChip(
    String label,
    String? levelValue,
    String? currentLevel,
  ) {
    final isSelected =
        levelValue == null ? currentLevel == null : currentLevel == levelValue;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) async {
        final notifier = ref.read(logsProvider.notifier);
        final filter = notifier.state.filter.copyWith(
          level: levelValue,
          offset: 0,
        );
        await notifier.applyFilter(filter);
      },
    );
  }

  void _showSavedFiltersSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final savedState = ref.watch(savedFiltersProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Saved Filters'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _showSaveCurrentFilterDialog();
                  },
                ),
              ),
              if (savedState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (savedState.filters.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('No saved filters yet'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: savedState.filters.length,
                    itemBuilder: (context, index) {
                      final saved = savedState.filters[index];
                      return ListTile(
                        title: Text(saved.name),
                        onTap: () async {
                          Navigator.of(context).pop();
                          await ref
                              .read(logsProvider.notifier)
                              .applyFilter(saved.filter);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            ref
                                .read(savedFiltersProvider.notifier)
                                .deleteFilter(saved.name);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSaveCurrentFilterDialog() async {
    final controller = TextEditingController();
    final filter = ref.read(logsProvider).filter;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Current Filter'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await ref
                      .read(savedFiltersProvider.notifier)
                      .saveFilter(name, filter);
                }
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveFiltersRow(LogsState state) {
    final filter = state.filter;
    final chips = <Widget>[];

    if (filter != null) {
      if (filter.level != null && filter.level!.isNotEmpty) {
        chips.add(_buildFilterChip('Level: ${filter.level}'));
      }
      if (filter.service != null && filter.service!.isNotEmpty) {
        chips.add(_buildFilterChip('Service: ${filter.service}'));
      }
      if (filter.statusCode != null) {
        chips.add(_buildFilterChip('Status: ${filter.statusCode}'));
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        chips.add(_buildFilterChip('Search: ${filter.searchQuery}'));
      }
    }

    if (chips.isEmpty) {
      return Text(
        'Showing latest logs',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips.map(
            (chip) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: chip,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ref.read(logsProvider.notifier).clearFilter();
            },
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      backgroundColor: AppColors.surfaceVariant,
      side: BorderSide(color: AppColors.border),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Logs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(logsProvider.notifier).loadLogs(refresh: true);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
          Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Logs Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
