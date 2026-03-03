import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/log_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/format_utils.dart';
import 'tabs/overview_tab.dart';
import 'tabs/request_tab.dart';
import 'tabs/response_tab.dart';
import 'tabs/error_tab.dart';
import 'tabs/timeline_tab.dart';

class LogDetailsPage extends StatefulWidget {
  final LogEntry log;
  const LogDetailsPage({super.key, required this.log});

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
    final c = AppColors.of(context);
    final log = widget.log;

    return Scaffold(
      backgroundColor: c.bg,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: c.textSecondary),
          ),
        ),
        title: Text(
          'Log Detail',
          style: AppTextStyles.h3.copyWith(color: c.textPrimary),
        ),
        actions: [
          // Copy trace ID shortcut
          if (log.traceId != null)
            _AppBarBtn(
              icon: Icons.copy_rounded,
              c: c,
              onTap: () {
                Clipboard.setData(ClipboardData(text: log.traceId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Trace ID copied',
                      style: AppTextStyles.monoSm,
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // ── 12-A: Header card ──────────────────────────────────────────
          _buildHeader(log, c),

          // ── 12-B: Custom tab bar ───────────────────────────────────────
          _buildTabBar(c),

          // ── Tab content ────────────────────────────────────────────────
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
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(LogEntry log, AppColorTokens c) {
    final levelColor = c.levelColor(log.level);
    final levelBg = c.levelBg(log.level);
    final statusColor = _statusColor(log.statusCode, c);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: levelColor, width: 3),
          top: BorderSide(color: c.border, width: 1),
          right: BorderSide(color: c.border, width: 1),
          bottom: BorderSide(color: c.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: level chip · service name · status badge
          Row(
            children: [
              // Level chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: levelBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: levelColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Text(
                  log.level.toUpperCase(),
                  style: AppTextStyles.label.copyWith(color: levelColor),
                ),
              ),
              const SizedBox(width: 10),
              // Service name
              Expanded(
                child: Text(
                  log.service,
                  style: AppTextStyles.monoMd
                      .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status badge
              if (log.statusCode != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${log.statusCode}',
                    style: AppTextStyles.monoSm.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: method + path — dark terminal container
          if (log.method != null && log.path != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    log.method!,
                    style: AppTextStyles.monoSm.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      log.path!,
                      style:
                          AppTextStyles.monoSm.copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          // Row 3: timestamp · duration
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: c.textTertiary),
              const SizedBox(width: 4),
              Text(
                date_utils.DateUtils.formatFull(log.timestamp),
                style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
              ),
              if (log.duration != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.bolt_rounded, size: 13, color: c.textTertiary),
                const SizedBox(width: 4),
                Text(
                  FormatUtils.formatDuration(log.duration!),
                  style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
                ),
              ],
            ],
          ),

          // Row 4: trace ID — accent link style with copy tap
          if (log.traceId != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: log.traceId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Trace ID copied',
                        style: AppTextStyles.monoSm),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.account_tree_rounded,
                      size: 13, color: c.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.traceId!,
                      style: AppTextStyles.monoSm.copyWith(
                        color: c.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: c.accent.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.copy_rounded, size: 12, color: c.accent),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar(AppColorTokens c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(7),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: c.textTertiary,
        labelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label,
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'REQUEST'),
          Tab(text: 'RESPONSE'),
          Tab(text: 'ERROR'),
          Tab(text: 'TIMELINE'),
        ],
      ),
    );
  }

  Color _statusColor(int? code, AppColorTokens c) {
    if (code == null) return c.border;
    if (code >= 500) return c.error;
    if (code >= 400) return c.warning;
    if (code >= 200 && code < 300) return c.success;
    return c.border;
  }
}

// ── AppBar icon button ────────────────────────────────────────────────────────

class _AppBarBtn extends StatelessWidget {
  const _AppBarBtn({required this.icon, required this.c, required this.onTap});
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
