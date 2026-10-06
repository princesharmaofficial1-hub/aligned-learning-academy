import 'package:flutter/material.dart';

/// Colour palettes for Aligned Learning.
///
/// Two palettes ship with the app:
///  * [AppPalette.dark]  — the primary, "cinematic dark" experience.
///  * [AppPalette.light] — the light exception, tuned for daytime reading.
///
/// Rule from the design system: never use pure `#000000` or pure `#FFFFFF` as
/// an app surface. Both smear on OLED panels and blow out under sunlight.
abstract final class AppPalette {
  // ---------------------------------------------------------------------------
  // Dark — primary
  // ---------------------------------------------------------------------------

  /// Page background. Deliberately a deep navy rather than pure black.
  static const Color darkBackground = Color(0xFF070B14);

  /// Slightly lifted background for recessed wells / app bars.
  static const Color darkBackgroundSunken = Color(0xFF050810);

  /// Default card surface.
  static const Color darkSurface = Color(0xFF0D1420);

  /// One step up: nested cards, list tiles inside cards.
  static const Color darkSurfaceRaised = Color(0xFF131C2C);

  /// Two steps up: popovers, menus, hovered rows.
  static const Color darkSurfaceOverlay = Color(0xFF1A2436);

  /// Translucent surface used for frosted headers and the nav dock.
  static const Color darkSurfaceGlass = Color(0xB30D1420);

  /// Hairline separator / card border.
  static const Color darkHairline = Color(0xFF1E2A3C);

  /// Emphasised border for selected or focused elements.
  static const Color darkHairlineStrong = Color(0xFF2E3E58);

  static const Color darkTextPrimary = Color(0xFFF2F6FC);
  static const Color darkTextSecondary = Color(0xFFA7B4C7);
  static const Color darkTextMuted = Color(0xFF7A8AA0);
  static const Color darkTextOnBrand = Color(0xFF04121E);

  // Brand + semantic
  static const Color darkBrand = Color(0xFF2E8FE0);
  static const Color darkBrandDeep = Color(0xFF1B77BC);
  static const Color darkBrandGlow = Color(0xFF56C2F5);
  static const Color darkGreen = Color(0xFF4ED44E);
  static const Color darkGreenSoft = Color(0xFF86EFAC);
  static const Color darkAccent = Color(0xFFF5A524);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFFB7185);
  static const Color darkInfo = Color(0xFF38BDF8);
  static const Color darkViolet = Color(0xFFA78BFA);

  static const Color darkScrim = Color(0xCC050810);

  // ---------------------------------------------------------------------------
  // Light — exception
  // ---------------------------------------------------------------------------

  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color lightBackgroundSunken = Color(0xFFE9EEF6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color lightSurfaceOverlay = Color(0xFFFFFFFF);
  static const Color lightSurfaceGlass = Color(0xE6FFFFFF);
  static const Color lightHairline = Color(0xFFDCE4EF);
  static const Color lightHairlineStrong = Color(0xFFBCC9DA);

  static const Color lightTextPrimary = Color(0xFF0B1220);
  static const Color lightTextSecondary = Color(0xFF46566B);
  static const Color lightTextMuted = Color(0xFF667A93);
  static const Color lightTextOnBrand = Color(0xFFFFFFFF);

  static const Color lightBrand = Color(0xFF1568AC);
  static const Color lightBrandDeep = Color(0xFF0F548F);
  static const Color lightBrandGlow = Color(0xFF2E8FE0);
  static const Color lightGreen = Color(0xFF16A34A);
  static const Color lightGreenSoft = Color(0xFF4ADE80);
  static const Color lightAccent = Color(0xFFB45309);
  static const Color lightSuccess = Color(0xFF15803D);
  static const Color lightWarning = Color(0xFFB45309);
  static const Color lightDanger = Color(0xFFC2263C);
  static const Color lightInfo = Color(0xFF0369A1);
  static const Color lightViolet = Color(0xFF6D42C7);

  static const Color lightScrim = Color(0x66101A28);
}
