import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Neo-Terminal Precision typography system.
///
/// Font stack:
///   Syne          — Display headings (geometric, technical, confident)
///   JetBrains Mono — Data, labels, code, timestamps, IDs
///   Inter          — Body text, descriptions, prose
///
/// Usage:
///   Text('System Overview', style: AppTextStyles.h2)
///   Text('42.3ms', style: AppTextStyles.mono)
///   Text('GET /api/v1/logs', style: AppTextStyles.monoSm)
class AppTextStyles {
  const AppTextStyles._();

  // ─────────────────────────────────────────────────────────────
  // DISPLAY — Syne 800 (large dashboard numbers, hero values)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get display => GoogleFonts.syne(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.1,
      );

  static TextStyle get displaySm => GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.75,
        height: 1.1,
      );

  // ─────────────────────────────────────────────────────────────
  // HEADINGS — Syne 700/600 (screen titles, section headers)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get h1 => GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get h2 => GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.syne(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get h4 => GoogleFonts.syne(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────
  // LABELS — JetBrains Mono 500 uppercase (chip labels, overlines,
  //          section category tags, status labels)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get label => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.4,
      );

  static TextStyle get labelMd => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────
  // MONO — JetBrains Mono 400/500 (paths, trace IDs, timestamps,
  //        response times, HTTP methods, JSON values)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle get monoMd => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle get monoSm => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get monoLg => GoogleFonts.jetBrainsMono(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
      );

  // ─────────────────────────────────────────────────────────────
  // BODY — Inter 400/500 (descriptions, messages, prose)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.6,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.55,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.55,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
      );

  static TextStyle get bodySmallMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.45,
      );

  // ─────────────────────────────────────────────────────────────
  // LEGACY ALIASES (kept for backward compat during migration)
  // These delegate to the new getter-based styles.
  // New widgets should use the getters directly.
  // ─────────────────────────────────────────────────────────────

  static TextStyle get overline => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.4,
      );

  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get codeSmall => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );
}
