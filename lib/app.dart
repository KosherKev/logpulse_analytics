import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
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

    final baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'LogPulse Analytics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: baseTextTheme.copyWith(
          headlineLarge: AppTextStyles.h1,
          headlineMedium: AppTextStyles.h2,
          titleLarge: AppTextStyles.h3,
          titleMedium: AppTextStyles.h4,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.body,
          bodySmall: AppTextStyles.bodySmall,
          labelSmall: AppTextStyles.overline,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: baseTextTheme.copyWith(
          headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.darkTextPrimary),
          headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.darkTextPrimary),
          titleLarge: AppTextStyles.h3.copyWith(color: AppColors.darkTextPrimary),
          titleMedium: AppTextStyles.h4.copyWith(color: AppColors.darkTextPrimary),
          bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
          bodyMedium: AppTextStyles.body.copyWith(color: AppColors.darkTextPrimary),
          bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.darkTextSecondary),
          labelSmall: AppTextStyles.overline.copyWith(color: AppColors.darkTextSecondary),
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
