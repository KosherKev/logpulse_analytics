import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/api_config_provider.dart';
import '../../../data/models/dashboard_stats.dart';
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

    return _buildDashboard(state.stats!);
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

  Widget _buildDashboard(DashboardStats stats) {
    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats overview
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Placeholder for stats cards - will add UI in later phase
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Logs: ${stats.totalLogs}'),
                  const SizedBox(height: 8),
                  Text('Error Rate: ${stats.formattedErrorRate}'),
                  const SizedBox(height: 8),
                  Text('Avg Latency: ${stats.formattedAvgLatency}'),
                  const SizedBox(height: 8),
                  Text('Requests/Hour: ${stats.requestsPerHour}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Services section
          if (stats.serviceStats != null) ...[
            Text(
              'Services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...stats.serviceStats!.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: Text(
                    'Error Rate: ${entry.value.errorRate.toStringAsFixed(1)}% | '
                    'Uptime: ${entry.value.formattedUptime}',
                  ),
                  trailing: Icon(
                    Icons.circle,
                    color: _getHealthColor(entry.value.healthStatus),
                    size: 12,
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Color _getHealthColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.unhealthy:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
