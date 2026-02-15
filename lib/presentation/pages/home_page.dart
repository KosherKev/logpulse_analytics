import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/logs/logs_page.dart';
import '../pages/errors/errors_page.dart';
import '../pages/settings/settings_page.dart';
import '../providers/navigation_provider.dart';

/// Main home scaffold with bottom navigation
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationProvider);

    final pages = [
      const DashboardPage(),
      const ErrorsPage(),
      const LogsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.error_outline),
            selectedIcon: Icon(Icons.error),
            label: 'Errors',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
