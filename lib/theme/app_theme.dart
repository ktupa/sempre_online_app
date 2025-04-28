import 'package:flutter/material.dart';

/// Paleta centralizada
class AppColors {
  // marca
  static const primary = Color(0xFF388E3C);
  static const secondary = Color(0xFF81C784);

  // textos
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF616161);

  // fundo e superfície – claro
  static const lightBackground = Color(0xFFF7F7F7);
  static const lightSurface = Colors.white;

  // fundo e superfície – escuro
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);

  // status cards (mantidos)
  static const statusOpen = Color(0xFF64B5F6);
  static const statusInProgress = Color(0xFFFFB74D);
  static const statusDone = Color(0xFF81C784);

  // sombreamento
  static const cardShadow = Color(0x22000000);
}

/// Fábrica genérica para evitar repetição
ThemeData _buildTheme(ColorScheme cs, bool isDark) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: cs.background,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withOpacity(.6),
      backgroundColor: cs.surface,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardTheme(
      color: cs.surface,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary),
      ),
    ),
  );
}

class AppTheme {
  static ThemeData get light => _buildTheme(
    const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
    ),
    false,
  );

  static ThemeData get dark => _buildTheme(
    const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
    ),
    true,
  );
}
