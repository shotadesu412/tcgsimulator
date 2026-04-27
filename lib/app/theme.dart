import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// T02: ライト/ダークテーマ、共通カラーパレット

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

abstract class AppColors {
  // Primary brand color — deep blue-green (card game feel)
  static const primary = Color(0xFF1A6B5A);
  static const primaryLight = Color(0xFF2D9B80);
  static const primaryDark = Color(0xFF0E4A3D);

  // Zone colors
  static const zoneBackground = Color(0xFF1E2A35);
  static const zoneBorder = Color(0xFF3A5068);
  static const zoneBorderHighlight = Color(0xFF4A9FD5);

  // Card
  static const cardBack = Color(0xFF2C3E50);
  static const cardTapped = Color(0xFF8B6914);
  static const cardSelected = Color(0xFF4A9FD5);

  // Surfaces
  static const surfaceDark = Color(0xFF141E28);
  static const surfaceMid = Color(0xFF1E2A35);
  static const surfaceLight = Color(0xFF253545);

  // Text
  static const textPrimary = Color(0xFFECF0F1);
  static const textSecondary = Color(0xFF95A5A6);
  static const textMuted = Color(0xFF5D7A8A);

  // Status
  static const error = Color(0xFFE74C3C);
  static const warning = Color(0xFFF39C12);
  static const success = Color(0xFF27AE60);
}

abstract class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceMid,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceMid,
        elevation: 2,
        margin: EdgeInsets.all(4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.zoneBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.zoneBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      dividerColor: AppColors.zoneBorder,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceMid,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceMid,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
