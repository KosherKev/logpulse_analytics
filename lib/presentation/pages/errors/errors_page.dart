import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/errors_provider.dart';
import '../../data/models/error_group.dart';
import '../../core/utils/date_utils.dart' as date_utils;

/// Errors Page - Error tracking and grouping
class ErrorsPage extends ConsumerStatefulWidget {
  const ErrorsPage({super.key});

  @override
  ConsumerState<ErrorsPage> createState() => _ErrorsPageState();
}

class _ErrorsPageState extends ConsumerState<ErrorsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(errorsProvider.notifier).loadErrors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final errorsState = ref.watch(errorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Errors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(errorsProvider.notifier).loadErrors();
            },
          ),
        ],
      ),
      body: _buildBody(errorsState),
    );
  }

  Widget _buildBody(ErrorsState state) {
    if (state.isLoading && state.errorGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.errorGroups.isEmpty) {
      return _buildError(state.error!);
    }

    if (state.errorGroups.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(errorsProvider.notifier).loadErrors(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total',
                  state.errorGroups.length.toString(),
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  '5xx',
                  state.errorGroups
                      .where((g) => g.instances?.any((i) => 
                          i.statusCode != null && i.statusCode! >= 500) ?? false)
                      .length
                      .toString(),
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  '4xx',
                  state.errorGroups
                      .where((g) => g.instances?.any((i) => 
                          i.statusCode != null && i.statusCode! >= 400 && i.statusCode! < 500) ?? false)
                      .length
                      .toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error Groups List
          const Text(
            'Error Groups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.errorGroups.map((group) => _buildErrorGroupCard(group)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorGroupCard(ErrorGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _showErrorDetails(group);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(group.severity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${group.count}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Services: ${group.formattedServices}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last: ${date_utils.DateUtils.formatRelative(group.lastSeen)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (group.trend != TrendDirection.stable)
                    Icon(
                      group.trend == TrendDirection.increasing
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 12,
                      color: group.trend == TrendDirection.increasing
                          ? Colors.red
                          : Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDetails(ErrorGroup group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(group.message),
            const SizedBox(height: 8),
            Text('Occurrences: ${group.count}'),
            Text('First seen: ${date_utils.DateUtils.formatRelative(group.firstSeen)}'),
            Text('Last seen: ${date_utils.DateUtils.formatRelative(group.lastSeen)}'),
            const SizedBox(height: 16),
            Text('Affected Services:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...group.services.map((s) => Text('• $s')),
          ],
        ),
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
            'Error Loading Errors',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Errors Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('All systems running smoothly!'),
        ],
      ),
    );
  }

  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.critical:
        return Colors.red;
      case ErrorSeverity.high:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.yellow[700]!;
      case ErrorSeverity.low:
        return Colors.blue;
    }
  }
}
