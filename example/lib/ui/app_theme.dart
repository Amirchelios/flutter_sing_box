import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF141318);
  static const Color coal = Color(0xFF1C1A20);
  static const Color sand = Color(0xFFF6EFE7);
  static const Color clay = Color(0xFFE7D8C5);
  static const Color coral = Color(0xFFE76F51);
  static const Color teal = Color(0xFF2A9D8F);
  static const Color amber = Color(0xFFF4A261);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.light,
    ).copyWith(
      primary: coral,
      secondary: teal,
      surface: sand,
      background: sand,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: sand,
      textTheme: GoogleFonts.spaceGroteskTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: sand,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: coal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6EFE7),
            Color(0xFFE9F0F2),
            Color(0xFFF5E5D7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -40,
            child: _GlowOrb(color: AppTheme.clay.withOpacity(0.6)),
          ),
          Positioned(
            left: -120,
            bottom: -60,
            child: _GlowOrb(color: AppTheme.teal.withOpacity(0.18)),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}
