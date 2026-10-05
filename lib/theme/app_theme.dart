import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ultra-deep dark surfaces
  static const Color background = Color(0xFF080C14);
  static const Color backgroundSecondary = Color(0xFF0D1322);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1B2436);
  static const Color surfaceGlass = Color(0xCC111827);
  static const Color cardBorder = Color(0xFF26334D);
  static const Color cardBorderGlow = Color(0xFF3B4D71);

  // Vibrant Aligned Automation Brand Accents
  static const Color brandBlue = Color(0xFF1B77BC); // Aligned Blue
  static const Color brandGreen = Color(0xFF4ED44E); // Aligned Green
  static const Color primary = Color(0xFF1B77BC); // Aligned Blue
  static const Color primaryGlow = Color(0xFF38BDF8); // Cyan Highlight
  static const Color secondary = Color(0xFF4ED44E); // Aligned Green
  static const Color secondaryGlow = Color(0xFF6EE7B7); // Light Green
  static const Color accent = Color(0xFFF59E0B); // Amber / Badges
  static const Color success = Color(0xFF22C55E); // Aligned Green
  static const Color danger = Color(0xFFEF4444); // Crimson
  static const Color purple = Color(0xFFA855F7); // Violet
  static const Color rose = Color(0xFFF43F5E); // Neon Rose

  // Tech Stack Signature Colors
  static const Color techPython = Color(0xFF38BDF8);
  static const Color techReact = Color(0xFF22D3EE);
  static const Color techNode = Color(0xFF4ADE80);
  static const Color techAngular = Color(0xFFF87171);
  static const Color techFastApi = Color(0xFF34D399);
  static const Color techDocker = Color(0xFF60A5FA);
  static const Color techGo = Color(0xFF38BDF8);
  static const Color techRust = Color(0xFFFB923C);
  static const Color techKafka = Color(0xFFE879F9);
  static const Color techSecurity = Color(0xFFA78BFA);

  static Color getTechColor(String tech) {
    switch (tech.toLowerCase()) {
      case 'python':
        return techPython;
      case 'react':
      case 'next.js':
        return techReact;
      case 'node.js':
      case 'express':
        return techNode;
      case 'angular':
        return techAngular;
      case 'fastapi':
        return techFastApi;
      case 'docker':
      case 'kubernetes':
        return techDocker;
      case 'go':
      case 'golang':
        return techGo;
      case 'rust':
        return techRust;
      case 'kafka':
        return techKafka;
      case 'cybersecurity':
      case 'security':
        return techSecurity;
      case 'flutter':
        return const Color(0xFF54C5F8);
      case 'aws':
        return const Color(0xFFFF9900);
      default:
        return primaryGlow;
    }
  }

  static String getTechEmoji(String tech) {
    switch (tech.toLowerCase()) {
      case 'fastapi':
        return '⚡';
      case 'react':
      case 'next.js':
        return '⚛️';
      case 'docker':
        return '🐳';
      case 'node.js':
        return '🟢';
      case 'kubernetes':
        return '☸️';
      case 'go':
      case 'golang':
        return '🚀';
      case 'rust':
        return '🦀';
      case 'aws':
        return '☁️';
      case 'kafka':
        return '📨';
      case 'flutter':
        return '📱';
      case 'angular':
        return '🔺';
      case 'python':
        return '🐍';
      case 'postgresql':
        return '🐘';
      case 'generative ai':
      case 'ai & machine learning':
        return '🤖';
      case 'cybersecurity':
        return '🛡️';
      default:
        return '💻';
    }
  }

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Brand Gradients
   static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF1B77BC), Color(0xFF4ED44E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B77BC), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyberGradient = LinearGradient(
    colors: [Color(0xFF1B77BC), Color(0xFF4ED44E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF125484), Color(0xFF1B77BC), Color(0xFF4ED44E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );


  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF141C2E), Color(0xFF0F1523)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Card Decorations
  static BoxDecoration glassCardDecoration({
    double radius = 18,
    Color borderColor = cardBorder,
    Color? surfaceColor,
  }) {
    return BoxDecoration(
      color: surfaceColor ?? surfaceGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(80),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration glowBoxDecoration({
    required Color glowColor,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glowColor.withAlpha(120), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: glowColor.withAlpha(40),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withAlpha(220),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: secondary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          color: textMuted,
        ),
      ),
    );
  }
}
