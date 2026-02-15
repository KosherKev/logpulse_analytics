import 'package:flutter/material.dart';
import '../../data/models/log_filter.dart';
import '../../core/constants/app_constants.dart';

/// Filter Dialog for logs
class FilterDialog extends StatefulWidget {
  final LogFilter initialFilter;
  final Function(LogFilter) onApply;

  const FilterDialog({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late String? selectedService;
  late String? selectedLevel;
  late int? selectedStatus;
  late DateTime? startDate;
  late DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialFilter.service;
    selectedLevel = widget.initialFilter.level;
    selectedStatus = widget.initialFilter.statusCode;
    startDate = widget.initialFilter.startDate;
    endDate = widget.initialFilter.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Logs'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service filter
            const Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedService,
              decoration: const InputDecoration(
                hintText: 'All services',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'user-api', child: Text('user-api')),
                DropdownMenuItem(value: 'payment-api', child: Text('payment-api')),
                DropdownMenuItem(value: 'order-api', child: Text('order-api')),
              ],
              onChanged: (value) => setState(() => selectedService = value),
            ),
            const SizedBox(height: 16),

            // Level filter
            const Text(
              'Level',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedLevel,
              decoration: const InputDecoration(
                hintText: 'All levels',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: AppConstants.levelError, child: Text('Error')),
                DropdownMenuItem(value: AppConstants.levelWarn, child: Text('Warning')),
                DropdownMenuItem(value: AppConstants.levelInfo, child: Text('Info')),
                DropdownMenuItem(value: AppConstants.levelDebug, child: Text('Debug')),
              ],
              onChanged: (value) => setState(() => selectedLevel = value),
            ),
            const SizedBox(height: 16),

            // Status Code filter
            const Text(
              'Status Code',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedStatus,
              decoration: const InputDecoration(
                hintText: 'All status codes',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 200, child: Text('2xx - Success')),
                DropdownMenuItem(value: 400, child: Text('4xx - Client Error')),
                DropdownMenuItem(value: 500, child: Text('5xx - Server Error')),
              ],
              onChanged: (value) => setState(() => selectedStatus = value),
            ),
            const SizedBox(height: 16),

            // Date range
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectStartDate(),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      startDate != null
                          ? '${startDate!.month}/${startDate!.day}'
                          : 'Start',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectEndDate(),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      endDate != null
                          ? '${endDate!.month}/${endDate!.day}'
                          : 'End',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _clearFilters,
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: _applyFilters,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => endDate = date);
    }
  }

  void _clearFilters() {
    setState(() {
      selectedService = null;
      selectedLevel = null;
      selectedStatus = null;
      startDate = null;
      endDate = null;
    });
  }

  void _applyFilters() {
    final filter = LogFilter(
      service: selectedService,
      level: selectedLevel,
      statusCode: selectedStatus,
      startDate: startDate,
      endDate: endDate,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }
}
