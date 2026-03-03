import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/errors_provider.dart';
import '../../../data/models/error_group.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/errors/summary_card.dart';
import '../../widgets/errors/error_group_card.dart';

class ErrorsPage extends ConsumerStatefulWidget {
  const ErrorsPage({super.key});

  @override
  ConsumerState<ErrorsPage> createState() => _ErrorsPageState();
}

class _ErrorsPageState extends ConsumerState<ErrorsPage> {
  // Local severity filter — no new API call, filters in-memory
  ErrorSeverity? _severityFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(errorsProvider.notifier).loadErrors());
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final state = ref.watch(errorsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: _buildAppBar(c, state),
      body: _buildBody(state, c),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(AppColorTokens c, ErrorsState state) {
    return AppBar(
      backgroundColor: c.bg,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: c.error),
          const SizedBox(width: 8),
          Text('Errors', style: AppTextStyles.h1.copyWith(color: c.textPrimary)),
        ],
      ),
      actions: [
        _IconBtn(
          icon: Icons.refresh_rounded,
          c: c,
          onTap: () => ref.read(errorsProvider.notifier).loadErrors(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(ErrorsState state, AppColorTokens c) {
    if (state.isLoading && state.errorGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.errorGroups.isEmpty) {
      return _buildErrorState(state.error!, c);
    }

    if (state.errorGroups.isEmpty) {
      return _buildEmpty(c);
    }

    // Compute summary counts
    final all = state.errorGroups;
    final serverGroups = all.where((g) => g.instances?.any(
          (i) => i.statusCode != null && i.statusCode! >= 500,
        ) ?? false).length;
    final clientGroups = all.where((g) => g.instances?.any(
          (i) => i.statusCode != null && i.statusCode! >= 400 && i.statusCode! < 500,
        ) ?? false).length;

    // Apply local severity filter
    final filtered = _severityFilter == null
        ? all
        : all.where((g) => g.severity == _severityFilter).toList();

    return RefreshIndicator(
      color: c.accent,
      onRefresh: () => ref.read(errorsProvider.notifier).loadErrors(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 11-A: Summary cards ─────────────────────────────
                  _buildSummaryCards(all.length, serverGroups, clientGroups, c),
                  const SizedBox(height: 20),

                  // ── 11-B: Severity filter tabs ──────────────────────
                  _buildSeverityTabs(all, c),
                  const SizedBox(height: 8),

                  // Results count divider
                  _buildResultsDivider(filtered.length, c),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // ── Error group list ─────────────────────────────────────────
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: _buildFilteredEmpty(c),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => ErrorGroupCard(
                  group: filtered[index],
                  onTap: () => _showErrorDetails(filtered[index], c),
                ),
                childCount: filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── 11-A: Summary cards row ───────────────────────────────────────────────
  //   Full-width total, then 2-col row for 5xx / 4xx

  Widget _buildSummaryCards(
    int total,
    int server,
    int client,
    AppColorTokens c,
  ) {
    return Column(
      children: [
        ErrorSummaryCard(
          label: 'Total Error Groups',
          value: total.toString(),
          color: c.error,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ErrorSummaryCard(
                label: '5xx Server Errors',
                value: server.toString(),
                color: c.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ErrorSummaryCard(
                label: '4xx Client Errors',
                value: client.toString(),
                color: c.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 11-B: Severity filter tabs ────────────────────────────────────────────

  Widget _buildSeverityTabs(List<ErrorGroup> all, AppColorTokens c) {
    // Count per severity
    int countFor(ErrorSeverity? sev) =>
        sev == null ? all.length : all.where((g) => g.severity == sev).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _SeverityTab(
            label: 'ALL',
            count: countFor(null),
            value: null,
            current: _severityFilter,
            activeColor: c.accent,
            activeBg: c.accentDim,
            c: c,
            onTap: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 6),
          _SeverityTab(
            label: 'CRITICAL',
            count: countFor(ErrorSeverity.critical),
            value: ErrorSeverity.critical,
            current: _severityFilter,
            activeColor: c.error,
            activeBg: c.errorBg,
            c: c,
            onTap: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 6),
          _SeverityTab(
            label: 'HIGH',
            count: countFor(ErrorSeverity.high),
            value: ErrorSeverity.high,
            current: _severityFilter,
            activeColor: c.warning,
            activeBg: c.warningBg,
            c: c,
            onTap: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 6),
          _SeverityTab(
            label: 'MEDIUM',
            count: countFor(ErrorSeverity.medium),
            value: ErrorSeverity.medium,
            current: _severityFilter,
            activeColor: c.info,
            activeBg: c.infoBg,
            c: c,
            onTap: (v) => setState(() => _severityFilter = v),
          ),
          const SizedBox(width: 6),
          _SeverityTab(
            label: 'LOW',
            count: countFor(ErrorSeverity.low),
            value: ErrorSeverity.low,
            current: _severityFilter,
            activeColor: c.debug,
            activeBg: c.debugBg,
            c: c,
            onTap: (v) => setState(() => _severityFilter = v),
          ),
        ],
      ),
    );
  }

  // ── Results count divider ─────────────────────────────────────────────────

  Widget _buildResultsDivider(int count, AppColorTokens c) {
    if (count == 0) return const SizedBox.shrink();
    final suffix = _severityFilter != null
        ? ' · ${_severityFilter!.name.toUpperCase()}'
        : '';
    return Row(
      children: [
        Text(
          '$count GROUPS$suffix',
          style: AppTextStyles.label.copyWith(color: c.textTertiary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.borderSoft, thickness: 1)),
      ],
    );
  }

  // ── 11-C: Error detail bottom sheet ──────────────────────────────────────

  void _showErrorDetails(ErrorGroup group, AppColorTokens c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: c.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // Header: error code + severity badge
            Row(
              children: [
                if (group.errorCode != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.errorBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: c.error.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Text(
                      group.errorCode!,
                      style:
                          AppTextStyles.label.copyWith(color: c.error),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _SeverityBadge(severity: group.severity, c: c),
                const Spacer(),
                // Count pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${group.count}×',
                    style: AppTextStyles.monoSm
                        .copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Message
            Text(
              group.message,
              style: AppTextStyles.bodyLarge.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 16),

            // Meta rows
            _DetailRow(
              label: 'FIRST SEEN',
              value: date_utils.DateUtils.formatRelative(group.firstSeen),
              c: c,
            ),
            _DetailRow(
              label: 'LAST SEEN',
              value: date_utils.DateUtils.formatRelative(group.lastSeen),
              c: c,
            ),
            _DetailRow(
              label: 'SERVICES',
              value: group.formattedServices,
              c: c,
            ),
            const SizedBox(height: 16),

            // Stack trace — dark terminal container
            if (group.stackTrace != null) ...[
              Text(
                'STACK TRACE',
                style: AppTextStyles.label.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.darkBorder, width: 1),
                ),
                child: SelectableText(
                  group.stackTrace!,
                  style: AppTextStyles.monoSm.copyWith(
                    color: AppColors.darkTextPrimary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Actions
            Text(
              'ACTIONS',
              style: AppTextStyles.label.copyWith(color: c.textTertiary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.search, size: 16, color: c.accent),
                    label: Text(
                      'Find Similar',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: c.accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: c.accent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.timeline, size: 16, color: c.accent),
                    label: Text(
                      'View Trace',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: c.accent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: c.accent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty states ──────────────────────────────────────────────────────────

  Widget _buildEmpty(AppColorTokens c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 52, color: c.success),
          const SizedBox(height: 16),
          Text('No Errors Found',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
          const SizedBox(height: 8),
          Text('All systems running smoothly',
              style: AppTextStyles.body.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildFilteredEmpty(AppColorTokens c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.filter_list_off, size: 40, color: c.textTertiary),
          const SizedBox(height: 12),
          Text(
            'No ${_severityFilter?.name ?? ''} errors',
            style: AppTextStyles.body.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, AppColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 52, color: c.error),
            const SizedBox(height: 16),
            Text('Failed to Load Errors',
                style: AppTextStyles.h2.copyWith(color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(error,
                style: AppTextStyles.body.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(errorsProvider.notifier).loadErrors(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

/// Severity filter pill with inline count badge
class _SeverityTab extends StatelessWidget {
  const _SeverityTab({
    required this.label,
    required this.count,
    required this.value,
    required this.current,
    required this.activeColor,
    required this.activeBg,
    required this.c,
    required this.onTap,
  });

  final String label;
  final int count;
  final ErrorSeverity? value;
  final ErrorSeverity? current;
  final Color activeColor;
  final Color activeBg;
  final AppColorTokens c;
  final void Function(ErrorSeverity?) onTap;

  bool get _selected => value == current;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _selected ? activeColor.withValues(alpha: 0.5) : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: _selected ? activeColor : c.textTertiary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _selected
                      ? activeColor.withValues(alpha: 0.2)
                      : c.surface2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.monoSm.copyWith(
                    color: _selected ? activeColor : c.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Severity badge for the detail sheet header
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity, required this.c});
  final ErrorSeverity severity;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (severity) {
      case ErrorSeverity.critical:
        color = c.error;
      case ErrorSeverity.high:
        color = c.warning;
      case ErrorSeverity.medium:
        color = c.info;
      case ErrorSeverity.low:
        color = c.debug;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: AppTextStyles.label.copyWith(color: color),
      ),
    );
  }
}

/// Label + value row for the detail sheet
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.c,
  });
  final String label;
  final String value;
  final AppColorTokens c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.monoSm.copyWith(color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot — red for errors page
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 5 * _scale.value,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AppBar icon button
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
