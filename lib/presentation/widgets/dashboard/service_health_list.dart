import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/dashboard_stats.dart';
import '../cards/service_health_card.dart';

class ServiceHealthList extends StatelessWidget {
  final Map<String, ServiceStats>? serviceStats;

  const ServiceHealthList({
    super.key,
    required this.serviceStats,
  });

  @override
  Widget build(BuildContext context) {
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
          ),
        ),
      ],
    );
  }
}
