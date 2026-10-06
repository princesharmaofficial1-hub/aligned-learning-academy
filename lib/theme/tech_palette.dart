import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Presentation metadata for technologies, document types and course levels.
///
/// Iconography is vector-only (Material Symbols) — never emoji, which is
/// font-dependent and cannot be themed or sized consistently.
abstract final class TechPalette {
  static const Map<String, Color> _colors = <String, Color>{
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
  };

  static const Map<String, IconData> _icons = <String, IconData>{
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
  };

  static Color colorFor(String tech) =>
      _colors[tech.trim().toLowerCase()] ?? AppPalette.darkBrandGlow;

  static IconData iconFor(String tech) =>
      _icons[tech.trim().toLowerCase()] ?? Icons.terminal_rounded;

  static Color levelColor(String level) => switch (level.trim().toLowerCase()) {
        'beginner' => AppPalette.darkBrandGlow,
        'intermediate' => AppPalette.darkGreen,
        'advanced' => AppPalette.darkViolet,
        'architect' || 'expert' => AppPalette.darkAccent,
        _ => AppPalette.darkGreen,
      };
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

  static Color colorFor(String type) => switch (type.trim().toLowerCase()) {
        'pdf' || 'book' || 'paper' => AppPalette.darkDanger,
        'code' || 'lab' || 'notebook' => AppPalette.darkInfo,
        'cheatsheet' || 'cheat sheet' || 'sheet' => AppPalette.darkAccent,
        'slides' || 'deck' => AppPalette.darkViolet,
        'video' => AppPalette.darkBrandGlow,
        'link' || 'url' => AppPalette.darkGreenSoft,
        _ => AppPalette.darkTextSecondary,
      };

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
