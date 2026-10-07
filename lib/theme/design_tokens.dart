import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Spacing scale — strict 4dp grid.
///
/// Use these instead of inline numbers so vertical rhythm is identical on every
/// screen. Two tiers matter most:
///  * [AppSpace.sm] … [AppSpace.xl] — inside components.
///  * [AppSpace.section] — between page sections.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
  static const double x5l = 48;
  static const double x6l = 64;

  /// Vertical rhythm between major page sections.
  static const double section = 28;

  /// Default horizontal page gutter.
  static const double gutter = 20;

  /// Minimum touch target (Android 48dp / iOS 44pt → use the larger).
  static const double touchTarget = 48;

  /// Bottom inset required so scrolling content clears the floating nav dock.
  static const double dockClearance = 104;
}

/// Corner radius scale. One radius per role — never a bespoke value.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  /// Circular icon container used across headers and list rows.
  static const BorderRadius iconSm = BorderRadius.all(Radius.circular(10));
  static const BorderRadius iconMd = BorderRadius.all(Radius.circular(14));
  static const BorderRadius iconLg = BorderRadius.all(Radius.circular(18));
}

/// Icon sizes — tokenised so rhythm never drifts.
abstract final class AppIcon {
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 32;
}

/// Motion tokens. Micro-interactions stay in the 150–300ms band per the
/// design system; page-level transitions may run to 400ms.
abstract final class AppMotion {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration page = Duration(milliseconds: 400);

  /// `cubic-bezier(0.16, 1, 0.3, 1)` — expo.out, decelerating.
  static const Curve emphasized = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOutQuart;
}

/// Alphas used for tinted fills. Replaces ad-hoc `withAlpha(n)` calls.
abstract final class AppAlpha {
  static const double wash = 0.08;
  static const double soft = 0.14;
  static const double medium = 0.24;
  static const double strong = 0.40;
  static const double glow = 0.30;
}

/// Cinematic visual layer.
///
/// Everything here is derived from the semantic tokens — screens never
/// hardcode gradients or glows. All values are theme-aware.
extension AppVisual on BuildContext {
  /// Full-bleed canvas: a brand-tinted top glow fading into the base canvas.
  /// Used behind the home destinations and as a screen wash behind content.
  LinearGradient get canvasGradient {
    final t = tokens;
    final top = isDarkMode
        ? Color.alphaBlend(
            AppPalette.darkBrand.withValues(alpha: 0.12), t.canvas)
        : Color.alphaBlend(
            AppPalette.lightBrand.withValues(alpha: 0.05), t.canvas);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[top, t.canvas, t.canvas],
      stops: const <double>[0.0, 0.4, 1.0],
    );
  }

  /// Brand glow blob — the ambient backdrop's warm light.
  Color get ambientGlow => isDarkMode
      ? AppPalette.darkBrand.withValues(alpha: 0.16)
      : AppPalette.lightBrand.withValues(alpha: 0.10);

  /// Violet counter-glow, sits in the opposite corner for depth.
  Color get ambientGlowSecondary => isDarkMode
      ? AppPalette.darkViolet.withValues(alpha: 0.12)
      : AppPalette.lightViolet.withValues(alpha: 0.08);

  /// Hairline top-edge highlight that gives elevated cards a frosted rim.
  Color get topEdgeHighlight => isDarkMode
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.05);

  /// Brand radiance cast behind primary controls.
  Color get buttonGlow => isDarkMode
      ? AppPalette.darkBrand.withValues(alpha: 0.42)
      : AppPalette.lightBrand.withValues(alpha: 0.30);
}

/// Semantic tokens that Material 3's [ColorScheme] has no slot for.
///
/// Read them with `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.canvasSunken,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.surfaceGlass,
    required this.hairline,
    required this.hairlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnBrand,
    required this.brand,
    required this.brandDeep,
    required this.brandGlow,
    required this.green,
    required this.greenSoft,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.violet,
    required this.scrim,
    required this.shadowStrong,
    required this.shadowSoft,
  });

  factory AppTokens.dark() => const AppTokens(
        canvas: AppPalette.darkBackground,
        canvasSunken: AppPalette.darkBackgroundSunken,
        surface: AppPalette.darkSurface,
        surfaceRaised: AppPalette.darkSurfaceRaised,
        surfaceOverlay: AppPalette.darkSurfaceOverlay,
        surfaceGlass: AppPalette.darkSurfaceGlass,
        hairline: AppPalette.darkHairline,
        hairlineStrong: AppPalette.darkHairlineStrong,
        textPrimary: AppPalette.darkTextPrimary,
        textSecondary: AppPalette.darkTextSecondary,
        textMuted: AppPalette.darkTextMuted,
        textOnBrand: AppPalette.darkTextOnBrand,
        brand: AppPalette.darkBrand,
        brandDeep: AppPalette.darkBrandDeep,
        brandGlow: AppPalette.darkBrandGlow,
        green: AppPalette.darkGreen,
        greenSoft: AppPalette.darkGreenSoft,
        accent: AppPalette.darkAccent,
        success: AppPalette.darkSuccess,
        warning: AppPalette.darkWarning,
        danger: AppPalette.darkDanger,
        info: AppPalette.darkInfo,
        violet: AppPalette.darkViolet,
        scrim: AppPalette.darkScrim,
        shadowStrong: Color(0x99000000),
        shadowSoft: Color(0x59000000),
      );

  factory AppTokens.light() => const AppTokens(
        canvas: AppPalette.lightBackground,
        canvasSunken: AppPalette.lightBackgroundSunken,
        surface: AppPalette.lightSurface,
        surfaceRaised: AppPalette.lightSurfaceRaised,
        surfaceOverlay: AppPalette.lightSurfaceOverlay,
        surfaceGlass: AppPalette.lightSurfaceGlass,
        hairline: AppPalette.lightHairline,
        hairlineStrong: AppPalette.lightHairlineStrong,
        textPrimary: AppPalette.lightTextPrimary,
        textSecondary: AppPalette.lightTextSecondary,
        textMuted: AppPalette.lightTextMuted,
        textOnBrand: AppPalette.lightTextOnBrand,
        brand: AppPalette.lightBrand,
        brandDeep: AppPalette.lightBrandDeep,
        brandGlow: AppPalette.lightBrandGlow,
        green: AppPalette.lightGreen,
        greenSoft: AppPalette.lightGreenSoft,
        accent: AppPalette.lightAccent,
        success: AppPalette.lightSuccess,
        warning: AppPalette.lightWarning,
        danger: AppPalette.lightDanger,
        info: AppPalette.lightInfo,
        violet: AppPalette.lightViolet,
        scrim: AppPalette.lightScrim,
        shadowStrong: Color(0x1F0B1220),
        shadowSoft: Color(0x140B1220),
      );

  final Color canvas;
  final Color canvasSunken;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color surfaceGlass;
  final Color hairline;
  final Color hairlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnBrand;
  final Color brand;
  final Color brandDeep;
  final Color brandGlow;
  final Color green;
  final Color greenSoft;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color violet;
  final Color scrim;
  final Color shadowStrong;
  final Color shadowSoft;

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? canvasSunken,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? surfaceGlass,
    Color? hairline,
    Color? hairlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnBrand,
    Color? brand,
    Color? brandDeep,
    Color? brandGlow,
    Color? green,
    Color? greenSoft,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? violet,
    Color? scrim,
    Color? shadowStrong,
    Color? shadowSoft,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      canvasSunken: canvasSunken ?? this.canvasSunken,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      hairline: hairline ?? this.hairline,
      hairlineStrong: hairlineStrong ?? this.hairlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      brandGlow: brandGlow ?? this.brandGlow,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      violet: violet ?? this.violet,
      scrim: scrim ?? this.scrim,
      shadowStrong: shadowStrong ?? this.shadowStrong,
      shadowSoft: shadowSoft ?? this.shadowSoft,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      canvasSunken: Color.lerp(canvasSunken, other.canvasSunken, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineStrong: Color.lerp(hairlineStrong, other.hairlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      brandGlow: Color.lerp(brandGlow, other.brandGlow, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
    );
  }
}

extension AppTokensContext on BuildContext {
  /// Semantic design tokens for the active theme.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;

  AppTokens? get maybeTokens => Theme.of(this).extension<AppTokens>();

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
