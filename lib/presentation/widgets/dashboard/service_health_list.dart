import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/models/log_filter.dart';
import '../cards/service_health_card.dart';
import '../../providers/logs_provider.dart';
import '../../providers/navigation_provider.dart';

class ServiceHealthList extends ConsumerWidget {
  final Map<String, ServiceStats>? serviceStats;

  const ServiceHealthList({
    super.key,
    required this.serviceStats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (serviceStats == null || serviceStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Health',
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...serviceStats!.entries.map(
          (entry) => ServiceHealthCard(
            serviceName: entry.key,
            stats: entry.value,
            onTap: () {
              ref
                  .read(logsProvider.notifier)
                  .applyFilter(LogFilter(service: entry.key));
              ref.read(navigationProvider.notifier).goToLogs();
            },
          ),
        ),
      ],
    );
  }
}
