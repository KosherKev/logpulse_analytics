import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../pages/service_details/service_details_page.dart';
import '../cards/service_health_card.dart';

/// "Service Health" section — header row with "view all →" + animated cards.
class ServiceHealthList extends ConsumerWidget {
  final Map<String, ServiceStats>? serviceStats;

  /// Max services to show before truncating (rest reachable via "view all")
  final int maxVisible;

  const ServiceHealthList({
    super.key,
    required this.serviceStats,
    this.maxVisible = 3,
  });

  void _openDetail(BuildContext context, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailsPage(serviceName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    if (serviceStats == null || serviceStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = serviceStats!.entries.toList();
    final visible = entries.take(maxVisible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Service Health',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
            const Spacer(),
            if (entries.length > maxVisible)
              GestureDetector(
                onTap: () {
                  // Open the first overflow service's catalog view — full
                  // services list can replace this when a dedicated tab exists.
                  _openDetail(context, entries[maxVisible].key);
                },
                child: Text(
                  'view all →',
                  style: AppTextStyles.monoSm.copyWith(color: c.accent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (entry) => ServiceHealthCard(
            serviceName: entry.key,
            stats: entry.value,
            onTap: () => _openDetail(context, entry.key),
          ),
        ),
      ],
    );
  }
}
