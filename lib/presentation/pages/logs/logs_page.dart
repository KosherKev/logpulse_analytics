import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/logs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/saved_filters_provider.dart';
import '../../providers/service_providers.dart';
import '../log_details/log_details_page.dart';
import '../../widgets/logs/enhanced_log_card.dart';
import '../../widgets/logs/skeleton_log_card.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    final c = AppColors.of(context);

    ref.listen<ApiConfigState>(apiConfigProvider, (previous, next) {
      final wasConfigured = previous?.isConfigured ?? false;
      if (!wasConfigured && next.isConfigured) {
        ref.read(logsProvider.notifier).loadLogs(refresh: true);
      }
    });

    final logsState = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(c),
      body: _buildBody(logsState, c),
      floatingActionButton: logsState.logs.isNotEmpty
          ? _ScrollTopFab(controller: _scrollController)
          : null,
    );
  }

  AppBar _buildAppBar(AppColorTokens c) {
    return AppBar(
      backgroundColor: c.bg,
      elevation: 0,
      titleSpacing: 16,
      title: Text(
        'Logs',
        style: AppTextStyles.h1.copyWith(color: c.textPrimary),
      ),
      actions: [
        _IconBtn(
          icon: Icons.tune,
          c: c,
          onTap: () => _showSavedFiltersSheet(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBody(LogsState state, AppColorTokens c) {
    // Full-page loading on first load
    if (state.isLoading && state.logs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        children: [
          _buildSearchBar(c),
          const SizedBox(height: 12),
          _buildLevelPills(state, c),
          const SizedBox(height: 16),
          for (var i = 0; i < 6; i++) const SkeletonLogCard(),
        ],
      );
    }

    if (state.error != null && state.logs.isEmpty) {
      return _buildError(state.error!, c);
    }

    return RefreshIndicator(
      color: c.accent,
      onRefresh: () => ref.read(logsProvider.notifier).loadLogs(refresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── Sticky search + filter header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(c),
                  const SizedBox(height: 12),
                  _buildLevelPills(state, c),
                  const SizedBox(height: 8),
                  _buildActiveFiltersRow(state, c),
                  const SizedBox(height: 8),
                  _buildResultsDivider(state, c),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // ── Log list ─────────────────────────────────────────────────
          if (state.logs.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty(c))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < state.logs.length) {
                    final log = state.logs[index];
                    return EnhancedLogCard(
                      log: log,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LogDetailsPage(log: log),
                        ),
                      ),
                    );
                  }
                  // Load-more footer: skeleton cards or end padding
                  if (!state.hasMore) {
                    return const SizedBox(height: 32);
                  }
                  return const SkeletonLogCard();
                },
                childCount: state.logs.length + (state.hasMore ? 3 : 1),
              ),
            ),
        ],
      ),
    );
  }

  // ── 10-A: Redesigned search bar ──────────────────────────────────────────

  Widget _buildSearchBar(AppColorTokens c) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocused ? c.accent : c.border,
          width: _searchFocused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, size: 18, color: c.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: AppTextStyles.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search logs, paths, trace IDs…',
                hintStyle: AppTextStyles.body.copyWith(color: c.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref.read(logsProvider.notifier).search(value);
                }
              },
            ),
          ),
          // ⌘K shortcut badge (cosmetic, shows keyboard shortcut hint)
          if (!_searchFocused && _searchController.text.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: c.border),
              ),
              child: Text(
                '⌘K',
                style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
              ),
            ),
          // Clear button when text present
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                ref.read(logsProvider.notifier).clearFilter();
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.close, size: 16, color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  // ── 10-B: Pill-style level filter chips ─────────────────────────────────

  Widget _buildLevelPills(LogsState state, AppColorTokens c) {
    final currentLevel = state.filter.level;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LevelPill(
            label: 'ALL',
            value: null,
            currentLevel: currentLevel,
            activeColor: c.accent,
            activeBg: c.accentDim,
            c: c,
            onTap: _applyLevel,
          ),
          const SizedBox(width: 6),
          _LevelPill(
            label: 'ERROR',
            value: AppConstants.levelError,
            currentLevel: currentLevel,
            activeColor: c.error,
            activeBg: c.errorBg,
            c: c,
            onTap: _applyLevel,
          ),
          const SizedBox(width: 6),
          _LevelPill(
            label: 'WARN',
            value: AppConstants.levelWarn,
            currentLevel: currentLevel,
            activeColor: c.warning,
            activeBg: c.warningBg,
            c: c,
            onTap: _applyLevel,
          ),
          const SizedBox(width: 6),
          _LevelPill(
            label: 'INFO',
            value: AppConstants.levelInfo,
            currentLevel: currentLevel,
            activeColor: c.info,
            activeBg: c.infoBg,
            c: c,
            onTap: _applyLevel,
          ),
          const SizedBox(width: 6),
          _LevelPill(
            label: 'DEBUG',
            value: AppConstants.levelDebug,
            currentLevel: currentLevel,
            activeColor: c.debug,
            activeBg: c.debugBg,
            c: c,
            onTap: _applyLevel,
          ),
        ],
      ),
    );
  }

  Future<void> _applyLevel(String? levelValue) async {
    final notifier = ref.read(logsProvider.notifier);
    final filter = ref.read(logsProvider).filter.copyWith(
      level: levelValue,
      offset: 0,
    );
    await notifier.applyFilter(filter);
  }

  // ── Active filter tags ───────────────────────────────────────────────────

  Widget _buildActiveFiltersRow(LogsState state, AppColorTokens c) {
    final filter = state.filter;
    final chips = <_ActiveTag>[];

    if (filter.service != null && filter.service!.isNotEmpty) {
      chips.add(_ActiveTag(label: 'svc: ${filter.service}', c: c));
    }
    if (filter.statusCode != null) {
      chips.add(_ActiveTag(label: 'status: ${filter.statusCode}', c: c));
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      chips.add(_ActiveTag(label: '"${filter.searchQuery}"', c: c));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips.map((chip) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: chip,
              )),
          GestureDetector(
            onTap: () => ref.read(logsProvider.notifier).clearFilter(),
            child: Text(
              'clear all',
              style: AppTextStyles.monoSm.copyWith(color: c.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── 10-C: Results count divider ──────────────────────────────────────────

  Widget _buildResultsDivider(LogsState state, AppColorTokens c) {
    final count = state.totalCount > 0
        ? state.totalCount
        : state.logs.length;
    if (count == 0) return const SizedBox.shrink();

    final hasError = state.filter.level == AppConstants.levelError;
    final priorityText = hasError ? ' · error priority' : '';

    return Row(
      children: [
        Expanded(child: Divider(color: c.borderSoft, thickness: 1)),
        const SizedBox(width: 10),
        Text(
          '$count results$priorityText',
          style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.borderSoft, thickness: 1)),
      ],
    );
  }

  // ── Empty & Error states ─────────────────────────────────────────────────

  Widget _buildEmpty(AppColorTokens c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 52, color: c.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No Logs Found',
            style: AppTextStyles.h2.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or time range',
            style: AppTextStyles.body.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, AppColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 52, color: c.error),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Logs',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.body.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(logsProvider.notifier).loadLogs(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 10-E: Saved filters bottom sheet ────────────────────────────────────

  void _showSavedFiltersSheet() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            final savedState = ref.watch(savedFiltersProvider);
            return Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'SAVED FILTERS',
                        style: AppTextStyles.label.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(sheetCtx).pop();
                          await _showSaveCurrentFilterDialog();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: c.accentDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: c.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '+ SAVE CURRENT',
                            style:
                                AppTextStyles.label.copyWith(color: c.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: savedState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : savedState.filters.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bookmarks_outlined,
                                      size: 40, color: c.textTertiary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No saved filters yet',
                                    style: AppTextStyles.body
                                        .copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: savedState.filters.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: c.borderSoft),
                              itemBuilder: (context, index) {
                                final saved = savedState.filters[index];
                                final f = saved.filter;
                                final summary = [
                                  if (f.level != null) f.level!.toUpperCase(),
                                  if (f.service != null) f.service!,
                                  if (f.statusCode != null)
                                    '${f.statusCode}',
                                  if (f.searchQuery != null &&
                                      f.searchQuery!.isNotEmpty)
                                    '"${f.searchQuery}"',
                                ].join(' · ');

                                return Dismissible(
                                  key: Key(saved.name),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: c.errorBg,
                                    child:
                                        Icon(Icons.delete_outline, color: c.error),
                                  ),
                                  onDismissed: (_) {
                                    ref
                                        .read(savedFiltersProvider.notifier)
                                        .deleteFilter(saved.name);
                                  },
                                  child: InkWell(
                                    onTap: () async {
                                      Navigator.of(sheetCtx).pop();
                                      await ref
                                          .read(logsProvider.notifier)
                                          .applyFilter(saved.filter);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  saved.name,
                                                  style: AppTextStyles.monoMd
                                                      .copyWith(
                                                          color: c.textPrimary),
                                                ),
                                                if (summary.isNotEmpty)
                                                  Text(
                                                    summary,
                                                    style: AppTextStyles.monoSm
                                                        .copyWith(
                                                            color:
                                                                c.textTertiary),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right,
                                              size: 16, color: c.textTertiary),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSaveCurrentFilterDialog() async {
    final c = AppColors.of(context);
    final controller = TextEditingController();
    final filter = ref.read(logsProvider).filter;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Filter',
          style: AppTextStyles.h3.copyWith(color: c.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Filter name'),
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
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

/// Pill-style level filter button — color-coded per log level
class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.label,
    required this.value,
    required this.currentLevel,
    required this.activeColor,
    required this.activeBg,
    required this.c,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String? currentLevel;
  final Color activeColor;
  final Color activeBg;
  final AppColorTokens c;
  final Future<void> Function(String?) onTap;

  bool get _selected =>
      value == null ? currentLevel == null : currentLevel == value;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _selected
                ? activeColor.withValues(alpha: 0.5)
                : c.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: _selected ? activeColor : c.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Active filter tag chip (non-dismissible, cleared via "clear all")
class _ActiveTag extends StatelessWidget {
  const _ActiveTag({required this.label, required this.c});
  final String label;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.monoSm.copyWith(color: c.textSecondary),
      ),
    );
  }
}

/// Scroll-to-top floating button
class _ScrollTopFab extends StatelessWidget {
  const _ScrollTopFab({required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.arrow_upward_rounded, size: 18, color: c.textSecondary),
      ),
    );
  }
}

/// AppBar icon button — bordered square matching dashboard style
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c, required this.onTap});
  final IconData icon;
  final AppColorTokens c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Icon(icon, size: 18, color: c.textSecondary),
      ),
    );
  }
}
