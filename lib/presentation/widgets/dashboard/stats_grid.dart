import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/dashboard_stats.dart';
import '../cards/stat_card.dart';

/// 2-column stat grid matching the mockup.
/// Each card has a distinct left-border accent color.
class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        StatCard(
          label: 'Total Logs',
          value: _formatCount(stats.totalLogs),
          accentColor: c.accent,
          delta: '↑ 12% vs yesterday',
          isPositive: true,
        ),
        StatCard(
          label: 'Error Rate',
          value: stats.formattedErrorRate,
          accentColor: c.error,
          delta: '↑ 0.2% from avg',
          isPositive: false,
        ),
        StatCard(
          label: 'Avg Latency',
          value: stats.formattedAvgLatency,
          accentColor: c.warning,
          delta: '→ stable',
          isPositive: null,
        ),
        StatCard(
          label: 'Req / Hour',
          value: _formatCount(stats.requestsPerHour),
          accentColor: c.success,
          delta: '↑ 8% peak',
          isPositive: true,
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
