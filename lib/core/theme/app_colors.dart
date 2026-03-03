import 'package:flutter/material.dart';

/// Neo-Terminal Precision design token system.
///
/// Light: Warm off-white studio, ink-black text, electric blue accent.
/// Dark: GitHub-dark deep slate, green-tinted surfaces, brighter accents.
///
/// Usage:
///   AppColors.light.bg         — light theme background
///   AppColors.dark.accent      — dark theme accent
///   AppColors.forBrightness(context) — auto-select based on Theme
class AppColors {
  const AppColors._();

  // ─────────────────────────────────────────────────────────────
  // LIGHT THEME TOKENS
  // ─────────────────────────────────────────────────────────────
  static const AppColorTokens light = AppColorTokens(
    // Backgrounds
    bg: Color(0xFFF7F6F3),
    bgAlt: Color(0xFFEFEEEB),

    // Surfaces
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F1EE),

    // Borders
    border: Color(0xFFE0DFDB),
    borderSoft: Color(0xFFEDECE9),

    // Text
    textPrimary: Color(0xFF0D0D0D),
    textSecondary: Color(0xFF4B4B4B),
    textTertiary: Color(0xFF8C8C8C),
    textInverse: Color(0xFFFFFFFF),

    // Accent (Electric Blue)
    accent: Color(0xFF0052FF),
    accentGlow: Color(0x1A0052FF),
    accentDim: Color(0xFFD6E4FF),

    // Status — Error
    error: Color(0xFFC8151B),
    errorBg: Color(0xFFFFF0F0),
    errorGlow: Color(0x1AC8151B),

    // Status — Warning
    warning: Color(0xFFB45309),
    warningBg: Color(0xFFFFFBEB),
    warningGlow: Color(0x1AB45309),

    // Status — Success
    success: Color(0xFF047857),
    successBg: Color(0xFFF0FDF4),
    successGlow: Color(0x1A047857),

    // Status — Info
    info: Color(0xFF0369A1),
    infoBg: Color(0xFFF0F9FF),

    // Log levels
    debug: Color(0xFF7C3AED),
    debugBg: Color(0xFFF5F3FF),

    // Pulse indicator
    pulse: Color(0xFF047857),
  );

  // ─────────────────────────────────────────────────────────────
  // DARK THEME TOKENS
  // ─────────────────────────────────────────────────────────────
  static const AppColorTokens dark = AppColorTokens(
    // Backgrounds — GitHub-dark deep slate
    bg: Color(0xFF0D1117),
    bgAlt: Color(0xFF090D12),

    // Surfaces — subtle green tint
    surface: Color(0xFF161B22),
    surface2: Color(0xFF1C2129),

    // Borders
    border: Color(0xFF30363D),
    borderSoft: Color(0xFF21262D),

    // Text
    textPrimary: Color(0xFFE6EDF3),
    textSecondary: Color(0xFF8B949E),
    textTertiary: Color(0xFF484F58),
    textInverse: Color(0xFF0D1117),

    // Accent (brighter blue for dark bg)
    accent: Color(0xFF2D7EFF),
    accentGlow: Color(0x1A2D7EFF),
    accentDim: Color(0xFF1C2D4A),

    // Status — Error
    error: Color(0xFFFF4D54),
    errorBg: Color(0xFF1F0F0F),
    errorGlow: Color(0x1AFF4D54),

    // Status — Warning
    warning: Color(0xFFF59E0B),
    warningBg: Color(0xFF1F1700),
    warningGlow: Color(0x1AF59E0B),

    // Status — Success
    success: Color(0xFF1DB954),
    successBg: Color(0xFF0D1F14),
    successGlow: Color(0x1A1DB954),

    // Status — Info
    info: Color(0xFF58A6FF),
    infoBg: Color(0xFF0D1F2D),

    // Log levels
    debug: Color(0xFFA78BFA),
    debugBg: Color(0xFF1A1030),

    // Pulse indicator
    pulse: Color(0xFF1DB954),
  );

  // ─────────────────────────────────────────────────────────────
  // LEGACY STATIC TOKENS (kept for backward compat during migration)
  // New code should use AppColors.light.* or AppColors.dark.*
  // ─────────────────────────────────────────────────────────────

  /// Returns tokens for the current theme brightness.
  static AppColorTokens of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // Commonly referenced legacy constants — mapped to new tokens
  static const Color primary = Color(0xFF0052FF);
  static const Color primaryDark = Color(0xFF0041CC);
  static const Color primaryLight = Color(0xFF2D7EFF);
  static const Color primaryLighter = Color(0xFFD6E4FF);

  static const Color accent = Color(0xFF0052FF);
  static const Color success = Color(0xFF047857);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFC8151B);
  static const Color errorLight = Color(0xFFFFF0F0);
  static const Color info = Color(0xFF0369A1);
  static const Color debug = Color(0xFF7C3AED);

  static const Color background = Color(0xFFF7F6F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F1EE);
  static const Color border = Color(0xFFE0DFDB);
  static const Color textPrimary = Color(0xFF0D0D0D);
  static const Color textSecondary = Color(0xFF4B4B4B);
  static const Color textDisabled = Color(0xFF8C8C8C);

  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF1C2129);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkInfo = Color(0xFF58A6FF);
}

// ─────────────────────────────────────────────────────────────
// TOKEN CONTAINER
// ─────────────────────────────────────────────────────────────

/// Strongly-typed color token container for a single theme variant.
class AppColorTokens {
  const AppColorTokens({
    required this.bg,
    required this.bgAlt,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.accentGlow,
    required this.accentDim,
    required this.error,
    required this.errorBg,
    required this.errorGlow,
    required this.warning,
    required this.warningBg,
    required this.warningGlow,
    required this.success,
    required this.successBg,
    required this.successGlow,
    required this.info,
    required this.infoBg,
    required this.debug,
    required this.debugBg,
    required this.pulse,
  });

  final Color bg;
  final Color bgAlt;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;
  final Color accent;
  final Color accentGlow;
  final Color accentDim;
  final Color error;
  final Color errorBg;
  final Color errorGlow;
  final Color warning;
  final Color warningBg;
  final Color warningGlow;
  final Color success;
  final Color successBg;
  final Color successGlow;
  final Color info;
  final Color infoBg;
  final Color debug;
  final Color debugBg;
  final Color pulse;

  /// Returns the level-appropriate color for a log level string.
  Color levelColor(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return error;
      case 'WARN':
      case 'WARNING':
        return warning;
      case 'INFO':
        return info;
      case 'DEBUG':
        return debug;
      default:
        return textTertiary;
    }
  }

  /// Returns the level-appropriate background color.
  Color levelBg(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return errorBg;
      case 'WARN':
      case 'WARNING':
        return warningBg;
      case 'INFO':
        return infoBg;
      case 'DEBUG':
        return debugBg;
      default:
        return surface2;
    }
  }
}
