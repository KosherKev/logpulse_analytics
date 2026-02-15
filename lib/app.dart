import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/service_providers.dart';

/// Main app widget
class LogPulseApp extends ConsumerStatefulWidget {
  const LogPulseApp({super.key});

  @override
  ConsumerState<LogPulseApp> createState() => _LogPulseAppState();
}

class _LogPulseAppState extends ConsumerState<LogPulseApp> {
  @override
  void initState() {
    super.initState();
    // Initialize app on startup
    Future.microtask(() {
      ref.read(apiConfigProvider.notifier).loadConfig();
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'LogPulse Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _getThemeMode(themeMode),
      home: const HomePage(),
    );
  }

  ThemeMode _getThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
