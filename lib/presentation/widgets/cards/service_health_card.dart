import 'package:flutter/material.dart';
import '../../../data/models/dashboard_stats.dart';

/// Service Health Card - Shows service status with health indicator
class ServiceHealthCard extends StatelessWidget {
  final String serviceName;
  final ServiceStats stats;
  final VoidCallback? onTap;

  const ServiceHealthCard({
    super.key,
    required this.serviceName,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final healthStatus = stats.healthStatus;
    final healthColor = _getHealthColor(healthStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Health indicator dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Error Rate: ${stats.errorRate.toStringAsFixed(1)}% • '
                      'Uptime: ${stats.formattedUptime}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.totalRequests}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'requests',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
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
