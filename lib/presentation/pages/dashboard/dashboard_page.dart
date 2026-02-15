import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/api_config_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../core/utils/format_utils.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/cards/service_health_card.dart';
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
    // Load dashboard data on init
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
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

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Time Range',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeRangeChip('last_hour', 'Last Hour', state.timeRange),
                _buildTimeRangeChip('last_24h', 'Last 24h', state.timeRange),
                _buildTimeRangeChip('last_7d', 'Last 7 Days', state.timeRange),
                _buildTimeRangeChip('last_30d', 'Last 30 Days', state.timeRange),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                title: 'Total Logs',
                value: FormatUtils.formatNumber(stats.totalLogs),
                icon: Icons.insert_chart,
              ),
              StatCard(
                title: 'Error Rate',
                value: stats.formattedErrorRate,
                icon: Icons.error_outline,
                color: Colors.red,
              ),
              StatCard(
                title: 'Avg Latency',
                value: stats.formattedAvgLatency,
                icon: Icons.speed,
              ),
              StatCard(
                title: 'Requests/Hour',
                value: FormatUtils.formatNumber(stats.requestsPerHour),
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (stats.serviceStats != null && stats.serviceStats!.isNotEmpty) ...[
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...stats.serviceStats!.entries.map((entry) {
              return ServiceHealthCard(
                serviceName: entry.key,
                stats: entry.value,
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label, String current) {
    final selected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (isSelected) {
          if (isSelected) {
            ref.read(dashboardProvider.notifier).setTimeRange(value);
          }
        },
      ),
    );
  }
}
