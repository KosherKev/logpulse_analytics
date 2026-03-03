import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Neo-Terminal Precision theme system.
///
/// Usage in app.dart:
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
class AppTheme {
  const AppTheme._();

  // ─────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(
        tokens: AppColors.light,
        brightness: Brightness.light,
        systemOverlay: SystemUiOverlayStyle.dark,
      );

  // ─────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _buildTheme(
        tokens: AppColors.dark,
        brightness: Brightness.dark,
        systemOverlay: SystemUiOverlayStyle.light,
      );

  // ─────────────────────────────────────────────────────────────
  // BUILDER
  // ─────────────────────────────────────────────────────────────
  static ThemeData _buildTheme({
    required AppColorTokens tokens,
    required Brightness brightness,
    required SystemUiOverlayStyle systemOverlay,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accent,
      onPrimary: tokens.textInverse,
      primaryContainer: tokens.accentDim,
      onPrimaryContainer: tokens.accent,
      secondary: tokens.textSecondary,
      onSecondary: tokens.textInverse,
      secondaryContainer: tokens.surface2,
      onSecondaryContainer: tokens.textPrimary,
      tertiary: tokens.info,
      onTertiary: tokens.textInverse,
      tertiaryContainer: tokens.infoBg,
      onTertiaryContainer: tokens.info,
      error: tokens.error,
      onError: tokens.textInverse,
      errorContainer: tokens.errorBg,
      onErrorContainer: tokens.error,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outline: tokens.border,
      outlineVariant: tokens.borderSoft,
      shadow: const Color(0xFF000000),
      scrim: const Color(0x80000000),
      inverseSurface: isDark ? tokens.textPrimary : tokens.bg,
      onInverseSurface: isDark ? tokens.bg : tokens.textPrimary,
      inversePrimary: isDark ? AppColors.light.accent : AppColors.dark.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // ── Scaffold ──────────────────────────────────────────
      scaffoldBackgroundColor: tokens.bg,

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bg,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h3.copyWith(color: tokens.textPrimary),
        systemOverlayStyle: systemOverlay.copyWith(
          statusBarColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: tokens.textSecondary, size: 22),
        actionsIconTheme: IconThemeData(color: tokens.textSecondary, size: 22),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Chip ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface2,
        selectedColor: tokens.accentDim,
        disabledColor: tokens.borderSoft,
        labelStyle: AppTextStyles.label.copyWith(color: tokens.textSecondary),
        secondaryLabelStyle: AppTextStyles.label.copyWith(color: tokens.accent),
        side: BorderSide(color: tokens.border, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelPadding: EdgeInsets.zero,
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),

      // ── Input / TextField ─────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.error, width: 1),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: tokens.textTertiary),
        labelStyle: AppTextStyles.bodySmall.copyWith(color: tokens.textSecondary),
        prefixIconColor: tokens.textTertiary,
        suffixIconColor: tokens.textTertiary,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.accentGlow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.accent, size: 22);
          }
          return IconThemeData(color: tokens.textTertiary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.label.copyWith(color: tokens.accent);
          }
          return AppTextStyles.label.copyWith(color: tokens.textTertiary);
        }),
        elevation: 0,
        height: 64,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: tokens.borderSoft,
        thickness: 1,
        space: 0,
      ),

      // ── Bottom Sheet ──────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: tokens.border,
        dragHandleSize: const Size(40, 4),
        elevation: 0,
        modalElevation: 0,
      ),

      // ── Dialog ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.h3.copyWith(color: tokens.textPrimary),
        contentTextStyle: AppTextStyles.body.copyWith(color: tokens.textSecondary),
        elevation: 0,
      ),

      // ── Snack Bar ─────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.textPrimary,
        contentTextStyle: AppTextStyles.bodySmall.copyWith(
          color: tokens.textInverse,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── Icon ──────────────────────────────────────────────
      iconTheme: IconThemeData(color: tokens.textSecondary, size: 20),

      // ── Elevated Button ───────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTextStyles.labelMd,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTextStyles.labelMd,
        ),
      ),

      // ── Text Button ───────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.labelMd,
        ),
      ),

      // ── Switch ────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accent;
          return tokens.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accentDim;
          return tokens.surface2;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.transparent;
          return tokens.border;
        }),
      ),

      // ── List Tile ─────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: tokens.textTertiary,
        textColor: tokens.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        titleTextStyle: AppTextStyles.body.copyWith(color: tokens.textPrimary),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(color: tokens.textSecondary),
      ),

      // ── Progress Indicator ────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.accentDim,
        circularTrackColor: tokens.accentDim,
        refreshBackgroundColor: tokens.surface,
      ),

      // ── Tab Bar ───────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: tokens.accent,
        unselectedLabelColor: tokens.textTertiary,
        labelStyle: AppTextStyles.label.copyWith(color: tokens.accent),
        unselectedLabelStyle: AppTextStyles.label.copyWith(color: tokens.textTertiary),
        indicatorColor: tokens.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: tokens.borderSoft,
      ),

      // ── Text Theme ────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display.copyWith(color: tokens.textPrimary),
        displayMedium: AppTextStyles.displaySm.copyWith(color: tokens.textPrimary),
        displaySmall: AppTextStyles.h1.copyWith(color: tokens.textPrimary),
        headlineLarge: AppTextStyles.h1.copyWith(color: tokens.textPrimary),
        headlineMedium: AppTextStyles.h2.copyWith(color: tokens.textPrimary),
        headlineSmall: AppTextStyles.h3.copyWith(color: tokens.textPrimary),
        titleLarge: AppTextStyles.h3.copyWith(color: tokens.textPrimary),
        titleMedium: AppTextStyles.h4.copyWith(color: tokens.textPrimary),
        titleSmall: AppTextStyles.bodyMedium.copyWith(color: tokens.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: tokens.textPrimary),
        bodyMedium: AppTextStyles.body.copyWith(color: tokens.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: tokens.textSecondary),
        labelLarge: AppTextStyles.labelMd.copyWith(color: tokens.textPrimary),
        labelMedium: AppTextStyles.label.copyWith(color: tokens.textSecondary),
        labelSmall: AppTextStyles.overline.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}
