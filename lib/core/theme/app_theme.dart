// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:psy/core/theme/theme_preferences.dart';
import 'app_colors.dart';
import 'agent_theme.dart';

class AppTheme {
  static ThemeData get current {
    final mode = ThemePreferences.instance.themeMode.value;
    final isDark = AppColors.isDarkMode;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    // Si hay un agente activo, usamos su ColorScheme personalizado
    final palette = agentPaletteFromMode(mode);
    final colorScheme = palette != null 
        ? palette.toColorScheme() 
        : ColorScheme.fromSeed(
            seedColor: ThemePreferences.instance.primaryColor,
            brightness: brightness,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter', 
      
      // --- APP BAR ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.8),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // --- TARJETAS ---
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),

      // --- BOTONES ELEVADOS (Primarios) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // --- BOTONES CON BORDE (Secundarios) ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.borderAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // --- CAMPOS DE TEXTO (INPUTS) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(color: AppColors.textMuted),
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),

      // --- DIVISORES ---
      dividerTheme: DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 24,
      ),

      // --- DIÁLOGOS Y BOTTOM SHEETS ---
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // --- SNACKBARS ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // --- ICONOS POR DEFECTO ---
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}