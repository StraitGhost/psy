// lib/core/theme/question_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class QuestionTheme {
  // ─────────────────────────────────────────────────────────────
  // COLORES BASE DINÁMICOS (Se adaptan al agente o tema oscuro/claro)
  // ─────────────────────────────────────────────────────────────
  static Color get background => AppColors.background;
  static Color get cardBackground => AppColors.surfaceCard;
  static Color get surface => AppColors.surface;
  static Color get surfaceLight => AppColors.surfaceElevated;
  static Color get border => AppColors.border;
  static Color get borderLight => AppColors.borderLight;
  
  // ─────────────────────────────────────────────────────────────
  // COLORES DE ESTADO Y ACCIÓN (Dinámicos)
  // ─────────────────────────────────────────────────────────────
  static Color get success => AppColors.success;
  static Color get error => AppColors.error;
  static Color get primary => AppColors.primary;
  static Color get primaryLight => AppColors.accent; // Tono secundario del agente
  static Color get warning => AppColors.warning;
  static Color get info => AppColors.info;
  
  // ─────────────────────────────────────────────────────────────
  // GRADIENTES DINÁMICOS (Usan los colores del agente activo)
  // ─────────────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get successGradient => LinearGradient(
    colors: [AppColors.success, AppColors.info],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get warningGradient => LinearGradient(
    colors: [AppColors.warning, AppColors.error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─────────────────────────────────────────────────────────────
  // PALETAS POR TIPO DE PREGUNTA
  // ─────────────────────────────────────────────────────────────
  static QuestionTypePalette getTypePalette(String type) {
    // OPCIÓN A: Si quieres que TODAS las preguntas usen los colores del agente:
    // return QuestionTypePalette(primary: AppColors.primary, secondary: AppColors.secondary);

    // OPCIÓN B (Recomendada): Mantener colores distintivos por tipo de pregunta 
    // para que el usuario identifique rápidamente el formato, pero asegurando 
    // que combinen bien con fondos oscuros.
    switch (type) {
      case 'opcion_multiple':
        return const QuestionTypePalette(
          primary: Color(0xFF4ED8FF), // Cyan
          secondary: Color(0xFF7561FF), // Púrpura
        );
      case 'verdadero_falso':
        return const QuestionTypePalette(
          primary: Color(0xFF31E6A1), // Verde
          secondary: Color(0xFF00B8FF), // Azul
        );
      case 'completar':
        return const QuestionTypePalette(
          primary: Color(0xFFFFC857), // Amarillo
          secondary: Color(0xFFFF7A8A), // Rojo/Rosa
        );
      case 'relacionar':
        return const QuestionTypePalette(
          primary: Color(0xFFB77CFF), // Púrpura claro
          secondary: Color(0xFF6A7BFF), // Azul medio
        );
      case 'ordenar':
        return const QuestionTypePalette(
          primary: Color(0xFF55A7FF), // Azul
          secondary: Color(0xFF9A6BFF), // Púrpura
        );
      default:
        // Fallback: usa los colores del agente activo
        return QuestionTypePalette(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        );
    }
  }
  
  // ─────────────────────────────────────────────────────────────
  // ESTILOS DE TEXTO (Adaptados al contraste del tema)
  // ─────────────────────────────────────────────────────────────
  static TextStyle get questionTitleStyle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.45,
    letterSpacing: 0.2,
  );
  
  static TextStyle get badgeStyle => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnPrimary, // Garantiza que el texto se lea sobre el fondo del badge
    letterSpacing: 0.5,
  );

  static TextStyle get optionTextStyle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

class QuestionTypePalette {
  final Color primary;
  final Color secondary;
  const QuestionTypePalette({required this.primary, required this.secondary});
}