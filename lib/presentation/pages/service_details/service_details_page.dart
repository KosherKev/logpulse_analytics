import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../data/models/log_filter.dart';
import '../../../data/models/service_summary.dart';
import '../../providers/logs_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/services_provider.dart';

/// Service detail — endpoints, health, metrics, instances (CLS P2).
class ServiceDetailsPage extends ConsumerWidget {
  final String serviceName;

  const ServiceDetailsPage({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(serviceDetailProvider(serviceName));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(
          serviceName,
          style: AppTextStyles.h2.copyWith(color: c.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.article_outlined, color: c.textSecondary),
            tooltip: 'View logs',
            onPressed: () {
              ref
                  .read(logsProvider.notifier)
                  .applyFilter(LogFilter(service: serviceName));
              Navigator.of(context).pop();
              ref.read(navigationProvider.notifier).goToLogs();
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString(),
                  style: AppTextStyles.body.copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(serviceDetailProvider(serviceName)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) => _DetailBody(detail: detail, c: c),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ServiceDetail detail;
  final AppColorTokens c;

  const _DetailBody({required this.detail, required this.c});

  @override
  Widget build(BuildContext context) {
    final s = detail.summary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _sectionLabel('OVERVIEW', c),
        const SizedBox(height: 8),
        _OverviewCard(summary: s, detail: detail, c: c),
        if (detail.healthStatus != null) ...[
          const SizedBox(height: 20),
          _sectionLabel('HEALTH', c),
          const SizedBox(height: 8),
          _HealthCard(detail: detail, c: c),
        ],
        if (detail.metrics != null && detail.metrics!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('CUSTOM METRICS', c),
          const SizedBox(height: 8),
          _MetricsCard(metrics: detail.metrics!, c: c),
        ],
        if (detail.instances.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('INSTANCES (${detail.instances.length})', c),
          const SizedBox(height: 8),
          ...detail.instances.map((i) => _InstanceRow(instance: i, c: c)),
        ],
        if (detail.endpoints.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionLabel('TOP ENDPOINTS', c),
          const SizedBox(height: 8),
          ...detail.endpoints.map((e) => _EndpointRow(endpoint: e, c: c)),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text, AppColorTokens c) {
    return Text(text, style: AppTextStyles.label.copyWith(color: c.textTertiary));
  }
}

class _OverviewCard extends StatelessWidget {
  final ServiceSummary summary;
  final ServiceDetail detail;
  final AppColorTokens c;

  const _OverviewCard({
    required this.summary,
    required this.detail,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.label,
            style: AppTextStyles.h3.copyWith(color: c.textPrimary),
          ),
          if (summary.displayName != null &&
              summary.displayName != summary.name) ...[
            const SizedBox(height: 4),
            Text(
              summary.name,
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _kv('requests', '${summary.totalRequests}', c),
              if (summary.errorRate != null)
                _kv('err', '${summary.errorRate!.toStringAsFixed(1)}%', c),
              if (summary.avgLatency != null)
                _kv('latency', '${summary.avgLatency!.toStringAsFixed(0)}ms', c),
              if (summary.instanceCount != null)
                _kv('instances', '${summary.instanceCount}', c),
              if (summary.lastSeen != null)
                _kv(
                  'last seen',
                  date_utils.DateUtils.formatRelative(summary.lastSeen!),
                  c,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, AppColorTokens c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: c.textTertiary)),
        const SizedBox(height: 2),
        Text(v, style: AppTextStyles.monoMd.copyWith(color: c.textPrimary)),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final ServiceDetail detail;
  final AppColorTokens c;

  const _HealthCard({required this.detail, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.healthStatus ?? '—',
            style: AppTextStyles.monoMd.copyWith(color: c.textPrimary),
          ),
          if (detail.uptimeSeconds != null) ...[
            const SizedBox(height: 4),
            Text(
              'uptime ${_formatDuration(detail.uptimeSeconds!)}',
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
            ),
          ],
          if (detail.healthInstanceId != null) ...[
            const SizedBox(height: 4),
            Text(
              'instance ${detail.healthInstanceId}',
              style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rm = m % 60;
    return rm == 0 ? '${h}h' : '${h}h ${rm}m';
  }
}

class _MetricsCard extends StatelessWidget {
  final Map<String, dynamic> metrics;
  final AppColorTokens c;

  const _MetricsCard({required this.metrics, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: metrics.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
                  ),
                ),
                Text(
                  _stringify(e.value),
                  style: AppTextStyles.monoMd.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _stringify(dynamic v) {
    if (v == null) return '—';
    if (v is num || v is bool || v is String) return v.toString();
    try {
      return jsonEncode(v);
    } catch (_) {
      return v.toString();
    }
  }
}

class _InstanceRow extends StatelessWidget {
  final ServiceInstance instance;
  final AppColorTokens c;

  const _InstanceRow({required this.instance, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              instance.instanceId,
              style: AppTextStyles.monoSm.copyWith(color: c.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (instance.status != null)
            Text(
              instance.status!,
              style: AppTextStyles.monoSm.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final EndpointStats endpoint;
  final AppColorTokens c;

  const _EndpointRow({required this.endpoint, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            endpoint.formattedEndpoint,
            style: AppTextStyles.monoSm.copyWith(color: c.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            [
              '${endpoint.requestCount} req',
              if (endpoint.errorRate != null)
                'err ${endpoint.errorRate!.toStringAsFixed(1)}%',
              if (endpoint.avgLatency != null)
                '${endpoint.avgLatency!.toStringAsFixed(0)}ms',
            ].join('  ·  '),
            style: AppTextStyles.monoSm.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}
