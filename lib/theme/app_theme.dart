import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';
import 'app_typography.dart';
import 'design_tokens.dart';
import 'tech_palette.dart';

/// Assembles the complete [ThemeData] for Aligned Learning.
///
/// Dark is the primary experience; light ships as a fully supported exception.
/// Both themes come from the same token set, so no screen can drift.
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // Public themes
  // ---------------------------------------------------------------------------

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  /// Back-compat alias used by older call sites.
  static ThemeData get darkTheme => dark;

  static ThemeMode get themeMode => ThemeMode.dark;

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final tokens = isDark ? AppTokens.dark() : AppTokens.light();

    final textPrimary =
        isDark ? AppPalette.darkTextPrimary : AppPalette.lightTextPrimary;
    final textSecondary = tokens.textSecondary;
    final textMuted = tokens.textMuted;
    final brand = tokens.brand;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: tokens.textOnBrand,
      primaryContainer: isDark
          ? AppPalette.darkSurfaceOverlay
          : AppPalette.lightBackgroundSunken,
      onPrimaryContainer: textPrimary,
      secondary: tokens.green,
      onSecondary: tokens.textOnBrand,
      secondaryContainer: tokens.green.withValues(alpha: AppAlpha.soft),
      onSecondaryContainer: tokens.greenSoft,
      tertiary: tokens.accent,
      onTertiary: tokens.textOnBrand,
      tertiaryContainer: tokens.accent.withValues(alpha: AppAlpha.soft),
      onTertiaryContainer: tokens.accent,
      error: tokens.danger,
      onError: isDark ? const Color(0xFF2A0710) : Colors.white,
      errorContainer: tokens.danger.withValues(alpha: AppAlpha.soft),
      onErrorContainer: tokens.danger,
      surface: tokens.surface,
      onSurface: textPrimary,
      surfaceContainerLowest: tokens.canvasSunken,
      surfaceContainerLow: tokens.canvas,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.surfaceRaised,
      surfaceContainerHighest: tokens.surfaceOverlay,
      onSurfaceVariant: textSecondary,
      outline: tokens.hairlineStrong,
      outlineVariant: tokens.hairline,
      shadow: Colors.black,
      scrim: tokens.scrim,
      inverseSurface:
          isDark ? AppPalette.darkSurfaceOverlay : const Color(0xFF1A2436),
      onInverseSurface: isDark ? AppPalette.darkTextPrimary : Colors.white,
      inversePrimary:
          isDark ? AppPalette.darkBrandDeep : AppPalette.lightBrandGlow,
      surfaceTint: brand,
    );

    final textTheme = AppTypography.build(
      brightness: brightness,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      shadowColor: Colors.black,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[tokens],

      // ---- App bar ----------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpace.lg,
        toolbarHeight: 60,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: textPrimary, size: AppIcon.md),
        actionsIconTheme: IconThemeData(color: textPrimary, size: AppIcon.md),
      ),

      // ---- Bottom navigation ------------------------------------------------
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surfaceGlass,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: brand.withValues(alpha: AppAlpha.medium),
        indicatorShape:
            const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppIcon.md,
            color: states.contains(WidgetState.selected) ? brand : textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: states.contains(WidgetState.selected) ? brand : textMuted,
          ),
        ),
      ),

      // ---- Cards ------------------------------------------------------------
      cardTheme: CardThemeData(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allLg,
          side: BorderSide(color: tokens.hairline),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),

      // ---- Buttons ----------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledStyle(tokens, textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledStyle(tokens, tokens.textOnBrand),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(textPrimary),
          minimumSize:
              const WidgetStatePropertyAll(Size(0, AppSpace.touchTarget)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpace.xl),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.hairlineStrong),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(brand),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpace.md),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(textSecondary),
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSpace.touchTarget, AppSpace.touchTarget),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          ),
        ),
      ),

      // ---- Inputs -----------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.darkBackgroundSunken : tokens.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.lg,
        ),
        hintStyle: textTheme.bodyMedium!.copyWith(color: textMuted),
        labelStyle: textTheme.bodyMedium,
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall!.copyWith(color: tokens.danger),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        border: _inputBorder(tokens.hairline),
        enabledBorder: _inputBorder(tokens.hairline),
        focusedBorder: _inputBorder(brand, width: 1.6),
        errorBorder: _inputBorder(tokens.danger),
        focusedErrorBorder: _inputBorder(tokens.danger, width: 1.6),
        disabledBorder: _inputBorder(tokens.hairline),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brand,
        selectionColor: brand.withValues(alpha: AppAlpha.medium),
        selectionHandleColor: brand,
      ),

      // ---- Chips ------------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceRaised,
        selectedColor: brand.withValues(alpha: AppAlpha.medium),
        side: BorderSide(color: tokens.hairline),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.sm),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        showCheckmark: false,
      ),

      // ---- Tabs -------------------------------------------------------------
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: brand, width: 2.5),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppIcon.sm / 2),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        overlayColor: WidgetStatePropertyAll<Color?>(
          brand.withValues(alpha: AppAlpha.wash),
        ),
      ),

      // ---- Switches / checkboxes / radios ----------------------------------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? tokens.textOnBrand : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? brand
              : (isDark
                  ? AppPalette.darkSurfaceOverlay
                  : AppPalette.lightBackgroundSunken),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? brand : tokens.hairlineStrong,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brand : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: tokens.hairlineStrong, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? brand : tokens.hairlineStrong,
        ),
      ),

      // ---- Progress ---------------------------------------------------------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: tokens.hairline,
        circularTrackColor: tokens.hairline,
        linearMinHeight: 6,
      ),

      // ---- Lists / tiles ----------------------------------------------------
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),

      // ---- Overlays ---------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: tokens.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allXl,
          side: BorderSide(color: tokens.hairline),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.surfaceRaised,
        modalBarrierColor: tokens.scrim,
        elevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceOverlay,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: textPrimary),
        actionTextColor: brand,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpace.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.surfaceOverlay,
          borderRadius: AppRadius.allSm,
          border: Border.all(color: tokens.hairline),
        ),
        textStyle: textTheme.bodySmall!.copyWith(color: textPrimary),
      ),

      // ---- Motion -----------------------------------------------------------
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ---- Misc -------------------------------------------------------------
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: tokens.textOnBrand,
        elevation: 0,
        highlightElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brand,
        inactiveTrackColor: tokens.hairline,
        thumbColor: brand,
        overlayColor: brand.withValues(alpha: AppAlpha.wash),
        trackHeight: 4,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: tokens.danger,
        textColor: Colors.white,
        textStyle: textTheme.labelSmall!.copyWith(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: textSecondary, size: AppIcon.md),
    );
  }

  static ButtonStyle _filledStyle(AppTokens tokens, Color foreground) {
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(foreground),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? tokens.surfaceRaised
            : tokens.brand,
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, AppSpace.touchTarget)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpace.xl),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
            fontSize: AppType.label,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.allMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ===========================================================================
  // Legacy tokens — deprecated.
  //
  // Retained only while screens are migrated onto `context.tokens` and the
  // shared components in `lib/widgets/app_components.dart`. Every one of these
  // resolves to the dark palette.
  // ===========================================================================

  static const Color background = AppPalette.darkBackground;
  static const Color backgroundSecondary = AppPalette.darkBackgroundSunken;
  static const Color surface = AppPalette.darkSurface;
  static const Color surfaceElevated = AppPalette.darkSurfaceRaised;
  static const Color surfaceGlass = AppPalette.darkSurfaceGlass;
  static const Color cardBorder = AppPalette.darkHairline;
  static const Color cardBorderGlow = AppPalette.darkHairlineStrong;

  static const Color brandBlue = AppPalette.darkBrandDeep;
  static const Color brandGreen = AppPalette.darkGreen;
  static const Color primary = AppPalette.darkBrand;
  static const Color primaryGlow = AppPalette.darkBrandGlow;
  static const Color secondary = AppPalette.darkGreen;
  static const Color secondaryGlow = AppPalette.darkGreenSoft;
  static const Color accent = AppPalette.darkAccent;
  static const Color success = AppPalette.darkSuccess;
  static const Color danger = AppPalette.darkDanger;
  static const Color purple = AppPalette.darkViolet;
  static const Color rose = AppPalette.darkDanger;

  static const Color textPrimary = AppPalette.darkTextPrimary;
  static const Color textSecondary = AppPalette.darkTextSecondary;
  static const Color textMuted = AppPalette.darkTextMuted;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppPalette.darkBrand, AppPalette.darkBrandDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [AppPalette.darkSurfaceRaised, AppPalette.darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration luxuryCardDecoration({
    double radius = AppRadius.lg,
    Color borderColor = AppPalette.darkHairline,
    Color? surfaceColor,
    bool hasGlow = false,
    Color glowColor = AppPalette.darkBrand,
  }) {
    return BoxDecoration(
      color: surfaceColor ?? AppPalette.darkSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: <BoxShadow>[
        if (hasGlow)
          BoxShadow(
            color: glowColor.withValues(alpha: 0.20),
            blurRadius: 22,
            spreadRadius: -2,
          ),
      ],
    );
  }

  // ---- Legacy helpers, delegating to the new palettes ----------------------
  static Color getTechColor(String tech) => TechPalette.colorFor(tech);
  static IconData getTechIcon(String tech) => TechPalette.iconFor(tech);
  static Color getLevelColor(String level) => TechPalette.levelColor(level);

  static const Color techPython = AppPalette.darkBrandGlow;
  static const Color techReact = AppPalette.darkInfo;
  static const Color techNode = AppPalette.darkGreen;
  static const Color techAngular = AppPalette.darkDanger;
  static const Color techFastApi = AppPalette.darkGreenSoft;
  static const Color techDocker = AppPalette.darkBrandGlow;
  static const Color techGo = AppPalette.darkInfo;
  static const Color techRust = AppPalette.darkAccent;
  static const Color techKafka = AppPalette.darkViolet;
  static const Color techSecurity = AppPalette.darkViolet;
}

/// Legacy token surface
// Kept so untouched screens keep compiling while they are migrated onto
// `context.tokens`. Values point at the dark palette because dark is the
// default experience. New code must not use these.
abstract final class AppThemeLegacy {
  static const Color background = AppPalette.darkBackground;
  static const Color backgroundSecondary = AppPalette.darkBackgroundSunken;
  static const Color surface = AppPalette.darkSurface;
  static const Color surfaceElevated = AppPalette.darkSurfaceRaised;
  static const Color surfaceGlass = AppPalette.darkSurfaceGlass;
  static const Color cardBorder = AppPalette.darkHairline;
  static const Color cardBorderGlow = AppPalette.darkHairlineStrong;

  static const Color brandBlue = AppPalette.darkBrandDeep;
  static const Color brandGreen = AppPalette.darkGreen;
  static const Color primary = AppPalette.darkBrand;
  static const Color primaryGlow = AppPalette.darkBrandGlow;
  static const Color secondary = AppPalette.darkGreen;
  static const Color secondaryGlow = AppPalette.darkGreenSoft;
  static const Color accent = AppPalette.darkAccent;
  static const Color success = AppPalette.darkSuccess;
  static const Color danger = AppPalette.darkDanger;
  static const Color purple = AppPalette.darkViolet;
  static const Color rose = AppPalette.darkDanger;

  static const Color textPrimary = AppPalette.darkTextPrimary;
  static const Color textSecondary = AppPalette.darkTextSecondary;
  static const Color textMuted = AppPalette.darkTextMuted;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppPalette.darkBrand, AppPalette.darkBrandDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
