import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/api_config_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/errors_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/error_group.dart';
import '../../widgets/dashboard/time_range_selector.dart';
import '../../widgets/dashboard/stats_grid.dart';
import '../../widgets/dashboard/error_rate_chart.dart';
import '../../widgets/dashboard/service_health_list.dart';
import '../../widgets/dashboard/recent_errors_list.dart';
/// Dashboard Page
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ref.read(navigationProvider.notifier).setIndex(3);
            },
          ),
        ],
      ),
      body: _buildBody(dashboardState, apiConfig),
    );
  }

  Widget _buildBody(DashboardState state, ApiConfigState apiConfig) {
    if (apiConfig.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!apiConfig.isConfigured) {
      return _buildNotConfigured();
    }

    if (state.isLoading && state.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildError(state.error!);
    }

    if (state.stats == null) {
      return const Center(child: Text('No data available'));
    }

    return _buildDashboard(state);
  }

  Widget _buildNotConfigured() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'API Not Configured',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please configure your API in Settings'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to settings will be implemented in next phase
            },
            icon: const Icon(Icons.settings),
            label: const Text('Go to Settings'),
          ),
        ],
      ),
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
            'Error Loading Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(dashboardProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DashboardState state) {
    final stats = state.stats!;
    final errorsState = ref.watch(errorsProvider);
    final errorGroups = errorsState.errorGroups
        .where((g) => g.severity == ErrorSeverity.critical || g.severity == ErrorSeverity.high)
        .toList();

    final series = state.timeSeries;
    final errorPoints = <FlSpot>[];
    final trafficPoints = <FlSpot>[];

    for (var i = 0; i < series.length; i++) {
      final point = series[i];
      final x = i.toDouble();
      errorPoints.add(FlSpot(x, point.errorRatePercent));
      trafficPoints.add(FlSpot(x, point.totalCount.toDouble()));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TimeRangeSelector(
            selectedRange: state.timeRange,
            onRangeChanged: (value) {
              ref.read(dashboardProvider.notifier).setTimeRange(value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          StatsGrid(stats: stats),
          const SizedBox(height: 24),
          ErrorRateChart(
            points: errorPoints,
            label: 'Error Rate',
            lineColor: AppColors.error,
            areaColor: AppColors.error.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          ErrorRateChart(
            points: trafficPoints,
            label: 'Traffic',
            lineColor: AppColors.primary,
            areaColor: AppColors.primary.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          ServiceHealthList(serviceStats: stats.serviceStats),
          const SizedBox(height: 24),
          RecentErrorsList(errorGroups: errorGroups),
        ],
      ),
    );
  }
}
