import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

/// Typography ramp.
///
/// * **Display / titles** → Outfit (geometric, distinctive, reads as "modern").
/// * **Body / UI** → Inter (high x-height, excellent at small sizes, technical).
/// * **Code / metadata** → JetBrains Mono for anything that looks like data.
///
/// Nothing in this ramp goes below 12dp except [AppType.overline], which is
/// uppercase + letter-spaced so it stays legible at that size.
abstract final class AppType {
  static const double display = 34;
  static const double h1 = 28;
  static const double h2 = 22;
  static const double h3 = 18;
  static const double title = 16;
  static const double body = 15;
  static const double bodySm = 13.5;
  static const double label = 13;
  static const double caption = 12;
  static const double overline = 11;
}

/// Named text styles that sit outside the Material [TextTheme] slots but recur
/// across the app (section eyebrows, numeric readouts, tech metadata).
extension AppTextStyles on TextTheme {
  /// Uppercase section label with wide tracking.
  TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: AppType.overline,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        height: 1.2,
      );

  /// Tabular-feeling numeric readout (progress %, lesson counts).
  TextStyle get metric => GoogleFonts.outfit(
        fontSize: AppType.h3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.1,
      );

  TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: AppType.caption,
        height: 1.4,
      );

  TextStyle get monoSmall => GoogleFonts.jetBrainsMono(
        fontSize: AppType.overline,
        letterSpacing: 0.2,
      );
}

/// Builds the themed [TextTheme] for a given brightness.
abstract final class AppTypography {
  static TextTheme build({
    required Brightness brightness,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isDark = brightness == Brightness.dark;

    final base = isDark
        ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return base.copyWith(
      // ---- Display & headings: Outfit, tight tracking -----------------------
      displayLarge: GoogleFonts.outfit(
        fontSize: AppType.display,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.1,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: AppType.h1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.15,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: AppType.h2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: AppType.h1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.15,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: AppType.h2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: AppType.h3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: textPrimary,
      ),

      // ---- Titles: Inter semibold, used inside cards and rows ----------------
      titleLarge: GoogleFonts.inter(
        fontSize: AppType.title,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: AppType.label,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: AppType.caption,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: textSecondary,
      ),

      // ---- Body: Inter ------------------------------------------------------
      bodyLarge: GoogleFonts.inter(
        fontSize: AppType.body,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: AppType.bodySm,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: AppType.caption,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: textMuted,
      ),

      // ---- Labels -----------------------------------------------------------
      labelLarge: GoogleFonts.inter(
        fontSize: AppType.label,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: AppType.caption,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: AppType.overline,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        height: 1.2,
        color: textMuted,
      ),
    );
  }

  /// Overline style, colour-injected by the caller.
  static TextStyle sectionLabel(Color color) => GoogleFonts.inter(
        fontSize: AppType.overline,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        height: 1.2,
        color: color,
      );

  /// Pill / badge label.
  static TextStyle pill(Color color) => GoogleFonts.inter(
        fontSize: AppType.overline,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        height: 1.1,
        color: color,
      );

  /// Monospace data readout.
  static TextStyle mono(Color color, {double size = AppType.caption}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        height: 1.4,
        color: color,
      );
}

/// Convenience access to the dark/light primary text colour for places that
/// need a colour but not a full theme.
abstract final class AppTextColors {
  static Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppPalette.darkTextPrimary
          : AppPalette.lightTextPrimary;

  static Color secondaryFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? AppPalette.darkTextSecondary
          : AppPalette.lightTextSecondary;

  static Color mutedFor(Brightness brightness) => brightness == Brightness.dark
      ? AppPalette.darkTextMuted
      : AppPalette.lightTextMuted;
}
