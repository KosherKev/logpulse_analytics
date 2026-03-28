import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/api_config_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/errors_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/error_group.dart';
import '../../widgets/dashboard/env_switcher_bar.dart';
import '../../widgets/dashboard/time_range_selector.dart';
import '../../widgets/dashboard/stats_grid.dart';
import '../../widgets/dashboard/error_rate_chart.dart';
import '../../widgets/dashboard/service_health_list.dart';
import '../../widgets/dashboard/recent_errors_list.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerCtrl;
  bool _hasAnimated = false;
  late Animation<double> _envFade;
  late Animation<Offset> _envSlide;
  late Animation<double> _rangeFade;
  late Animation<Offset> _rangeSlide;
  late Animation<double> _statsFade;
  late Animation<Offset> _statsSlide;
  late Animation<double> _chartFade;
  late Animation<Offset> _chartSlide;
  late Animation<double> _healthFade;
  late Animation<Offset> _healthSlide;
  late Animation<double> _errorsFade;
  late Animation<Offset> _errorsSlide;
  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _envFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.0, 0.2));
    _envSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.0, 0.2)));
    _rangeFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.1, 0.3));
    _rangeSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.1, 0.3)));
    _statsFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.2, 0.4));
    _statsSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.2, 0.4)));
    _chartFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.3, 0.5));
    _chartSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.3, 0.5)));
    _healthFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.4, 0.6));
    _healthSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.4, 0.6)));
    _errorsFade = CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.5, 0.7));
    _errorsSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _staggerCtrl, curve: const Interval(0.5, 0.7)));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Reload data when API becomes configured
    ref.listen<ApiConfigState>(apiConfigProvider, (previous, next) {
      final wasConfigured = previous?.isConfigured ?? false;
      if (!wasConfigured && next.isConfigured) {
        ref.read(dashboardProvider.notifier).loadStats();
        ref.read(errorsProvider.notifier).loadErrors();
      }
    });

    final dashboardState = ref.watch(dashboardProvider);
    final apiConfig = ref.watch(apiConfigProvider);

    return Scaffold(
      backgroundColor: c.bg,
      // ── AppBar: LogPulse · pulse dot · bell · search ─────────────────────
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            _PulseDot(color: c.pulse),
            const SizedBox(width: 8),
            Text(
              'LogPulse',
              style: AppTextStyles.h1.copyWith(color: c.textPrimary),
            ),
          ],
        ),
        actions: [
          _AppBarIconButton(
            icon: Icons.notifications_outlined,
            color: c,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _AppBarIconButton(
            icon: Icons.search,
            color: c,
            onTap: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildBody(dashboardState, apiConfig, c),
    );
  }

  Widget _buildBody(
    DashboardState state,
    ApiConfigState apiConfig,
    AppColorTokens c,
  ) {
    if (apiConfig.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!apiConfig.isConfigured) {
      return _buildUnconfigured(c, apiConfig.isFirstRun);
    }

    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.stats == null) {
      return _buildError(state.error!, c);
    }

    return _buildDashboard(state, c);
  }

  // ── Unconfigured state ────────────────────────────────────────────────────
  Widget _buildUnconfigured(AppColorTokens c, bool isFirstRun) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFirstRun ? Icons.playlist_add : Icons.settings_outlined,
              size: 56,
              color: c.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isFirstRun ? 'Welcome to LogPulse' : 'API Not Configured',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFirstRun
                  ? 'Add your first API connection in Settings'
                  : 'Configure your API key in Settings',
              style: AppTextStyles.body.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(navigationProvider.notifier).goToSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────
  Widget _buildError(String error, AppColorTokens c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: c.error),
            const SizedBox(height: 16),
            Text(
              'Dashboard Error',
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
                  ref.read(dashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main dashboard ────────────────────────────────────────────────────────
  Widget _buildDashboard(DashboardState state, AppColorTokens c) {
    final stats = state.stats!;

    // Build chart series from time-series data
    final series = state.timeSeries;
    final trafficPoints = <FlSpot>[];
    final errorPoints = <FlSpot>[];

    for (var i = 0; i < series.length; i++) {
      final x = i.toDouble();
      trafficPoints.add(FlSpot(x, series[i].totalCount.toDouble()));
      errorPoints.add(FlSpot(x, series[i].errorRatePercent));
    }

    // Error groups for recent errors section
    final errorsState = ref.watch(errorsProvider);
    final criticalErrors = errorsState.errorGroups
        .where((g) =>
            g.severity == ErrorSeverity.critical ||
            g.severity == ErrorSeverity.high)
        .toList();

    if (!_hasAnimated) {
      _hasAnimated = true;
      _staggerCtrl.forward();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          FadeTransition(
            opacity: _envFade,
            child: SlideTransition(
              position: _envSlide,
              child: const EnvSwitcherBar(),
            ),
          ),
          const SizedBox(height: 16),

          FadeTransition(
            opacity: _rangeFade,
            child: SlideTransition(
              position: _rangeSlide,
              child: TimeRangeSelector(
                selectedRange: state.timeRange,
                onRangeChanged: (value) =>
                    ref.read(dashboardProvider.notifier).setTimeRange(value),
              ),
            ),
          ),
          const SizedBox(height: 16),

          FadeTransition(
            opacity: _statsFade,
            child: SlideTransition(
              position: _statsSlide,
              child: StatsGrid(stats: stats),
            ),
          ),
          const SizedBox(height: 16),

          FadeTransition(
            opacity: _chartFade,
            child: SlideTransition(
              position: _chartSlide,
              child: ErrorRateChart(
                trafficPoints: trafficPoints,
                errorPoints: errorPoints,
                subtitle: _chartSubtitle(state.timeRange),
              ),
            ),
          ),
          const SizedBox(height: 24),

          FadeTransition(
            opacity: _healthFade,
            child: SlideTransition(
              position: _healthSlide,
              child: ServiceHealthList(serviceStats: stats.serviceStats),
            ),
          ),
          const SizedBox(height: 24),

          if (criticalErrors.isNotEmpty)
            FadeTransition(
              opacity: _errorsFade,
              child: SlideTransition(
                position: _errorsSlide,
                child: RecentErrorsList(errorGroups: criticalErrors),
              ),
            ),
        ],
      ),
    );
  }

  String _chartSubtitle(String timeRange) {
    switch (timeRange) {
      case 'last_hour':
        return 'last 1h · 5m buckets';
      case 'last_7d':
        return 'last 7d · 6h buckets';
      case 'last_30d':
        return 'last 30d · 1d buckets';
      default:
        return 'last 24h · 1h buckets';
    }
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

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
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.8, end: 1.3).animate(
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

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final AppColorTokens color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Icon(icon, size: 18, color: c.textSecondary),
      ),
    );
  }
}
