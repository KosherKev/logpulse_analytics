import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../providers/api_config_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/errors_provider.dart';
import '../providers/logs_provider.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';

/// Starts a periodic refresh of dashboard, logs, errors, and services when
/// auto-refresh is enabled and the API is configured.
///
/// Place once above the main shell (e.g. [HomePage]). Passes [child] through.
class AutoRefreshBinder extends ConsumerStatefulWidget {
  final Widget child;

  const AutoRefreshBinder({super.key, required this.child});

  @override
  ConsumerState<AutoRefreshBinder> createState() => _AutoRefreshBinderState();
}

class _AutoRefreshBinderState extends ConsumerState<AutoRefreshBinder> {
  Timer? _timer;
  bool? _lastEnabled;
  int? _lastInterval;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _applySchedule({required bool enabled, required int intervalSeconds}) {
    if (_lastEnabled == enabled && _lastInterval == intervalSeconds) {
      // Already running with these settings (or already off).
      if (!enabled || (_timer?.isActive ?? false)) return;
    }

    _lastEnabled = enabled;
    _lastInterval = intervalSeconds;
    _timer?.cancel();
    _timer = null;

    if (!enabled) return;

    final seconds = intervalSeconds.clamp(
      AppConstants.minRefreshInterval.inSeconds,
      AppConstants.maxRefreshInterval.inSeconds,
    );

    _timer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (!mounted) return;
      if (!ref.read(apiConfigProvider).isConfigured) return;
      if (!ref.read(settingsProvider).autoRefresh) return;

      ref.read(dashboardProvider.notifier).refresh();
      ref.read(logsProvider.notifier).loadLogs(refresh: true);
      ref.read(errorsProvider.notifier).loadErrors();
      ref.read(servicesListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final configured = ref.watch(apiConfigProvider).isConfigured;
    final enabled = settings.autoRefresh && configured;

    // Keep timer in sync with watched state.
    _applySchedule(
      enabled: enabled,
      intervalSeconds: settings.refreshInterval,
    );

    return widget.child;
  }
}
