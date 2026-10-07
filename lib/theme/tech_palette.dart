import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Presentation metadata for technologies, document types and course levels.
///
/// Iconography is vector-only (Material Symbols) — never emoji, which is
/// font-dependent and cannot be themed or sized consistently.
abstract final class TechPalette {
  static const Map<String, Color> _colors = <String, Color>{
    'azure': Color(0xFF0089D6),
    'microsoft azure': Color(0xFF0089D6),
    'azure devops': Color(0xFF0078D4),
    'gcp': Color(0xFF4285F4),
    'google cloud': Color(0xFF4285F4),
    'terraform': Color(0xFF844FBA),
    'iac': Color(0xFF844FBA),
    'devops': Color(0xFF00C7B7),
    'ci/cd': Color(0xFF00C7B7),
    'cloud': Color(0xFF0288D1),
    'linux': Color(0xFFFCC624),
    'bash': Color(0xFF4EAA25),
    'system design': Color(0xFFFFB300),
    'architecture': Color(0xFFFFB300),
    'python': AppPalette.darkBrandGlow,
    'react': AppPalette.darkInfo,
    'next.js': AppPalette.darkInfo,
    'node.js': AppPalette.darkGreen,
    'express': AppPalette.darkGreen,
    'angular': AppPalette.darkDanger,
    'fastapi': AppPalette.darkGreenSoft,
    'docker': AppPalette.darkBrandGlow,
    'kubernetes': AppPalette.darkBrandGlow,
    'go': AppPalette.darkInfo,
    'golang': AppPalette.darkInfo,
    'rust': AppPalette.darkAccent,
    'kafka': AppPalette.darkViolet,
    'cybersecurity': AppPalette.darkViolet,
    'security': AppPalette.darkViolet,
    'flutter': Color(0xFF54C5F8),
    'aws': Color(0xFFFF9900),
    'postgresql': AppPalette.darkBrandGlow,
    'generative ai': AppPalette.darkViolet,
    'ai & machine learning': AppPalette.darkViolet,
    'typescript': Color(0xFF3178C6),
    'javascript': Color(0xFFF7DF1E),
    'data structures': Color(0xFF8E44AD),
    'algorithms': Color(0xFF8E44AD),
    'java': Color(0xFFED8B00),
    'spring boot': Color(0xFF6DB33F),
    'c++': Color(0xFF00599C),
    'microservices': Color(0xFF00B4D8),
    'data engineering': Color(0xFF0288D1),
    'analytics': Color(0xFF4285F4),
    'vue': Color(0xFF42B883),
    'pinia': Color(0xFFFFD859),
    'django': Color(0xFF092E20),
    'react native': Color(0xFF61DAFB),
    'c#': Color(0xFF512BD4),
    'csharp': Color(0xFF512BD4),
    '.net': Color(0xFF512BD4),
    'dotnet': Color(0xFF512BD4),
    'c# / .net': Color(0xFF512BD4),
    'kotlin': Color(0xFF7F52FF),
    'android': Color(0xFF3DDC84),
    'android / kotlin': Color(0xFF7F52FF),
    'swift': Color(0xFFF05138),
    'ios': Color(0xFFF05138),
    'swiftui': Color(0xFFF05138),
    'ios / swift': Color(0xFFF05138),
    'php': Color(0xFF777BB4),
    'laravel': Color(0xFFFF2D20),
    'php & laravel': Color(0xFFFF2D20),
    'mongodb': Color(0xFF47A248),
    'nosql': Color(0xFF47A248),
    'redis': Color(0xFFDC382D),
    'graphql': Color(0xFFE10098),
    'git': Color(0xFFF05032),
    'github': Color(0xFFF05032),
    'git & github': Color(0xFFF05032),
    'ethical hacking': Color(0xFF00E676),
    'kali linux': Color(0xFF00E676),
    'sql': Color(0xFF4479A1),
    'mysql': Color(0xFF4479A1),
    'html': Color(0xFFE34F26),
    'html5': Color(0xFFE34F26),
    'css': Color(0xFF1572B6),
    'css3': Color(0xFF1572B6),
    'spring': Color(0xFF6DB33F),
  };

  static const Map<String, IconData> _icons = <String, IconData>{
    'azure': Icons.cloud_circle_rounded,
    'microsoft azure': Icons.cloud_circle_rounded,
    'azure devops': Icons.all_inclusive_rounded,
    'gcp': Icons.cloud_sync_rounded,
    'google cloud': Icons.cloud_sync_rounded,
    'terraform': Icons.layers_rounded,
    'iac': Icons.layers_rounded,
    'devops': Icons.all_inclusive_rounded,
    'ci/cd': Icons.published_with_changes_rounded,
    'cloud': Icons.cloud_rounded,
    'linux': Icons.terminal_rounded,
    'bash': Icons.code_rounded,
    'system design': Icons.architecture_rounded,
    'architecture': Icons.account_tree_rounded,
    'python': Icons.code_rounded,
    'react': Icons.widgets_rounded,
    'next.js': Icons.widgets_rounded,
    'node.js': Icons.hub_rounded,
    'express': Icons.hub_rounded,
    'angular': Icons.change_history_rounded,
    'fastapi': Icons.bolt_rounded,
    'docker': Icons.inventory_2_rounded,
    'kubernetes': Icons.hub_rounded,
    'go': Icons.rocket_launch_rounded,
    'golang': Icons.rocket_launch_rounded,
    'rust': Icons.settings_rounded,
    'kafka': Icons.swap_horiz_rounded,
    'cybersecurity': Icons.shield_rounded,
    'security': Icons.shield_rounded,
    'flutter': Icons.phone_iphone_rounded,
    'aws': Icons.cloud_rounded,
    'postgresql': Icons.storage_rounded,
    'generative ai': Icons.auto_awesome_rounded,
    'ai & machine learning': Icons.auto_awesome_rounded,
    'typescript': Icons.integration_instructions_rounded,
    'javascript': Icons.javascript_rounded,
    'data structures': Icons.account_tree_rounded,
    'algorithms': Icons.scatter_plot_rounded,
    'java': Icons.coffee_rounded,
    'spring boot': Icons.eco_rounded,
    'spring': Icons.eco_rounded,
    'c++': Icons.memory_rounded,
    'microservices': Icons.scatter_plot_rounded,
    'data engineering': Icons.analytics_rounded,
    'analytics': Icons.analytics_rounded,
    'vue': Icons.splitscreen_rounded,
    'pinia': Icons.grain_rounded,
    'django': Icons.dns_rounded,
    'react native': Icons.stay_current_portrait_rounded,
    'c#': Icons.developer_mode_rounded,
    'csharp': Icons.developer_mode_rounded,
    '.net': Icons.developer_mode_rounded,
    'dotnet': Icons.developer_mode_rounded,
    'c# / .net': Icons.developer_mode_rounded,
    'kotlin': Icons.android_rounded,
    'android': Icons.android_rounded,
    'android / kotlin': Icons.android_rounded,
    'swift': Icons.phone_iphone_rounded,
    'ios': Icons.phone_iphone_rounded,
    'swiftui': Icons.phone_iphone_rounded,
    'ios / swift': Icons.phone_iphone_rounded,
    'php': Icons.web_rounded,
    'laravel': Icons.web_rounded,
    'php & laravel': Icons.web_rounded,
    'mongodb': Icons.storage_rounded,
    'nosql': Icons.storage_rounded,
    'redis': Icons.flash_on_rounded,
    'graphql': Icons.hub_rounded,
    'git': Icons.fork_right_rounded,
    'github': Icons.fork_right_rounded,
    'git & github': Icons.fork_right_rounded,
    'ethical hacking': Icons.security_rounded,
    'kali linux': Icons.security_rounded,
    'sql': Icons.table_chart_rounded,
    'mysql': Icons.table_chart_rounded,
    'html': Icons.language_rounded,
    'html5': Icons.language_rounded,
    'css': Icons.brush_rounded,
    'css3': Icons.brush_rounded,
  };

  static Color colorFor(String tech, {Brightness brightness = Brightness.dark}) =>
      TechContrast.ensure(
        _colors[tech.trim().toLowerCase()] ?? AppPalette.darkBrandGlow,
        brightness,
      );

  static IconData iconFor(String tech) =>
      _icons[tech.trim().toLowerCase()] ?? Icons.terminal_rounded;

  static Color levelColor(String level,
          {Brightness brightness = Brightness.dark}) =>
      switch (level.trim().toLowerCase()) {
        'beginner' => TechContrast.ensure(
            AppPalette.darkBrandGlow, brightness),
        'intermediate' => TechContrast.ensure(AppPalette.darkGreen, brightness),
        'advanced' => TechContrast.ensure(AppPalette.darkViolet, brightness),
        'architect' || 'expert' => TechContrast.ensure(
            AppPalette.darkAccent, brightness),
        _ => TechContrast.ensure(AppPalette.darkGreen, brightness),
      };
}

/// Resolves accent colours so they pass 4.5:1 contrast on the canvas of the
/// active theme.
///
/// The brand/tech accents are authored against the dark palette. In light mode
/// they wash out (e.g. `#56C2F5` on white ≈ 1.9:1), and a few dark brand
/// colours (`#092E20`) fail in dark mode. [ensure] moves the colour away from
/// the canvas — toward black on a light canvas, toward white on a dark one —
/// until the WCAG ratio is met, preserving hue.
abstract final class TechContrast {
  static const double minRatio = 4.5;

  static Color ensure(Color color, Brightness brightness) {
    final canvas = brightness == Brightness.light
        ? AppPalette.lightBackground
        : AppPalette.darkBackground;
    return ensureOn(color, canvas);
  }

  /// Darkens/lightens [color] until it contrasts [background] by [minRatio].
  static Color ensureOn(Color color, Color background,
      {double minRatio = TechContrast.minRatio}) {
    final towardLight = _luminance(background) < 0.4;
    final limit = towardLight ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    var result = color;
    for (var i = 0; i < 24 && _contrast(result, background) < minRatio; i++) {
      result = Color.lerp(result, limit, 0.10)!;
    }
    return result;
  }

  /// WCAG 2.1 relative luminance.
  static double _luminance(Color color) {
    double channel(double v) {
      final c = v / 255;
      return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r * 255) +
        0.7152 * channel(color.g * 255) +
        0.0722 * channel(color.b * 255);
  }

  static double _contrast(Color a, Color b) {
    final la = _luminance(a);
    final lb = _luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Theme-aware accessors so screens never hardcode an accent against a
/// brightness they don't control.
extension TechPaletteContext on BuildContext {
  Brightness get _accentBrightness => Theme.of(this).brightness;

  Color techColor(String tech) =>
      TechPalette.colorFor(tech, brightness: _accentBrightness);

  Color levelColor(String level) =>
      TechPalette.levelColor(level, brightness: _accentBrightness);

  Color docColor(String type) =>
      DocPalette.colorFor(type, brightness: _accentBrightness);
}

/// Presentation metadata for course resource documents.
abstract final class DocPalette {
  static IconData iconFor(String type) => switch (type.trim().toLowerCase()) {
        'pdf' || 'book' || 'paper' => Icons.picture_as_pdf_rounded,
        'code' || 'lab' || 'notebook' => Icons.code_rounded,
        'cheatsheet' || 'cheat sheet' || 'sheet' => Icons.description_rounded,
        'slides' || 'deck' => Icons.slideshow_rounded,
        'video' => Icons.play_circle_fill_rounded,
        'link' || 'url' => Icons.link_rounded,
        _ => Icons.insert_drive_file_rounded,
      };

  static Color colorFor(String type, {Brightness brightness = Brightness.dark}) {
    final raw = switch (type.trim().toLowerCase()) {
      'pdf' || 'book' || 'paper' => AppPalette.darkDanger,
      'code' || 'lab' || 'notebook' => AppPalette.darkInfo,
      'cheatsheet' || 'cheat sheet' || 'sheet' => AppPalette.darkAccent,
      'slides' || 'deck' => AppPalette.darkViolet,
      'video' => AppPalette.darkBrandGlow,
      'link' || 'url' => AppPalette.darkGreenSoft,
      _ => AppPalette.darkTextSecondary,
    };
    return TechContrast.ensure(raw, brightness);
  }

  static String labelFor(String type) => switch (type.trim().toLowerCase()) {
        'pdf' || 'book' || 'paper' => 'PDF',
        'code' || 'lab' || 'notebook' => 'Code',
        'cheatsheet' || 'cheat sheet' || 'sheet' => 'Cheatsheet',
        'slides' || 'deck' => 'Slides',
        'video' => 'Video',
        'link' || 'url' => 'Link',
        _ => 'Resource',
      };
}
