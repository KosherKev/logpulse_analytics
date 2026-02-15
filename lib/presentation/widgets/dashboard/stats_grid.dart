import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/dashboard_stats.dart';
import '../cards/stat_card.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = MediaQuery.of(context).size.width < 600 ? 1 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          title: 'Total Logs',
          value: stats.totalLogs.toString(),
          icon: Icons.insert_chart,
        ),
        StatCard(
          title: 'Error Rate',
          value: stats.formattedErrorRate,
          icon: Icons.error_outline,
        ),
        StatCard(
          title: 'Avg Latency',
          value: stats.formattedAvgLatency,
          icon: Icons.speed,
        ),
        StatCard(
          title: 'Requests/Hour',
          value: stats.requestsPerHour.toString(),
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}
