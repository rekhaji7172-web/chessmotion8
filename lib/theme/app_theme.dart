import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Background Colors ─────────────────────────────────────────
  static const Color bgDark    = Color(0xFF080D18);
  static const Color bgCard    = Color(0xFF0D1526);
  static const Color bgPanel   = Color(0xFF111C30);
  static const Color bgSurface = Color(0xFF172035);
  static const Color bgHover   = Color(0xFF1E2A42);

  // ── Brand Colors ───────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark  = Color(0xFF0D47A1);

  static const Color accent      = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFCC02);
  static const Color accentRed   = Color(0xFFE53935);
  static const Color accentCyan  = Color(0xFF00BCD4);
  static const Color accentGold  = Color(0xFFFFD700);

  // ── Text Colors ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textHint      = Color(0xFF3D4A60);

  // ── UI Colors ──────────────────────────────────────────────────────
  static const Color divider  = Color(0xFF1A2438);
  static const Color border   = Color(0xFF202E48);
  static const Color selected = Color(0xFF1976D2);

  // ── Gradients ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFE65100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF080D18), Color(0xFF0D1A2E), Color(0xFF0A1228)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient timelineGradient = LinearGradient(
    colors: [Color(0xFF080D18), Color(0xFF0D1526)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Chess Piece Colors ─────────────────────────────────────────────
  static const Color chessDark  = Color(0xFF1A2744);
  static const Color chessLight = Color(0xFFB0BEC5);
  static const Color chessBrown = Color(0xFF8B5E3C);
  static const Color chessCream = Color(0xFFF0D9B5);

  // ── Layer Track Colors ─────────────────────────────────────────────
  static const List<Color> layerColors = [
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF0277BD),
    Color(0xFF4527A0),
  ];

  // ── Theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgCard,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      // CardTheme: correct Flutter 3.24 API
      cardTheme: CardTheme(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 20),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textHint),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: bgSurface,
        overlayColor: Color(0x29F5A623),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0x80F5A623)
              : bgSurface,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: bgSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        textStyle: const TextStyle(color: textPrimary, fontSize: 12),
      ),
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────
  static Color layerColorAt(int index) =>
      layerColors[index % layerColors.length];

  static BoxDecoration get panelDecoration => const BoxDecoration(
        color: bgPanel,
        border: Border(right: BorderSide(color: border)),
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      );

  static BoxDecoration get glowDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      );
}
