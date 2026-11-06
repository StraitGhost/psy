// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';
import 'agent_theme.dart';
import 'theme_preferences.dart';

class AppColors {
  static String get _mode => ThemePreferences.instance.themeMode.value;

  static bool get isDarkMode {
    final mode = _mode;
    if (mode == 'light') return false;
    if (mode == 'dark') return true;
    if (isAgentMode(mode)) return true; // Los temas de agentes son oscuros
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  static AgentPalette? get _p => agentPaletteFromMode(_mode);
  static bool get hasAgentTheme => _p != null;

  // --- COLORES DE IDENTIDAD ---
  static Color get primary => _p?.primary ?? ThemePreferences.instance.primaryColor;
  static Color get secondary => _p?.secondary ?? ThemePreferences.instance.primaryColor.withOpacity(0.7);
  static Color get accent => _p?.accent ?? secondary;
  static Color get tertiary => _p?.tertiary ?? const Color(0xFF1E293B);

  // --- SUPERFICIES Y FONDOS ---
  static Color get background => _p?.background ?? (isDarkMode ? const Color(0xFF0A0E1A) : const Color(0xFFF9FAFB));
  static Color get backgroundSecondary => _p?.backgroundSecondary ?? (isDarkMode ? const Color(0xFF0F1525) : const Color(0xFFF3F4F6));
  static Color get surface => _p?.surface ?? (isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF));
  static Color get surfaceCard => _p?.surfaceCard ?? (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6));
  static Color get surfaceElevated => _p?.surfaceElevated ?? (isDarkMode ? const Color(0xFF253349) : const Color(0xFFFFFFFF));

  // --- SIDEBAR / NAVEGACIÓN ---
  static Color get sidebarBg => _p?.sidebarBg ?? (isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF));
  static Color get sidebarItem => _p?.sidebarItem ?? (isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFF3F4F6));
  static Color get sidebarItemActive => _p?.sidebarItemActive ?? (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE0E7FF));
  static Color get sidebarText => isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  static Color get sidebarTextActive => isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF111827);

  // --- TEXTO ---
  static Color get textPrimary => _p?.textPrimary ?? (isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827));
  static Color get textSecondary => _p?.textSecondary ?? (isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563));
  static Color get textMuted => _p?.textMuted ?? (isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF));
  static Color get textOnPrimary => _p?.textOnPrimary ?? Colors.white;
  static Color get textOnSecondary => _p?.textOnSecondary ?? Colors.white;

  // --- BORDES ---
  static Color get border => _p?.border ?? (isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB));
  static Color get borderLight => _p?.borderLight ?? (isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6));
  static Color get borderAccent => _p?.borderAccent ?? primary; // ¡Clave para resaltar!

  // --- ESTADOS (Ahora dinámicos según el agente, con fallback) ---
  static Color get success => _p?.success ?? const Color(0xFF10B981);
  static Color get warning => _p?.warning ?? const Color(0xFFF59E0B);
  static Color get error => _p?.error ?? const Color(0xFFEF4444);
  static Color get info => _p?.info ?? const Color(0xFF3B82F6);

  // --- UTILIDADES ---
  static Color on(Color c) => _p?.on(c) ?? (ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : const Color(0xFF0B0F1A));
}