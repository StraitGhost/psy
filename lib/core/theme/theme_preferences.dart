// lib/core/theme/theme_preferences.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'agent_theme.dart';

class ThemePreferences {
  ThemePreferences._();
  static final ThemePreferences instance = ThemePreferences._();

  static const Color defaultColor = Color(0xFF6366F1);

  static const List<(String, String, Color)> colorThemes = [
    ('default', 'Predeterminado', defaultColor),
    ('ocean', 'Océano', Color(0xFF00B4DB)),
    ('forest', 'Bosque', Color(0xFF11998E)),
    ('sunset', 'Atardecer', Color(0xFFFF512F)),
    ('rose', 'Rosa', Color(0xFFE91E63)),
    ('midnight', 'Medianoche', Color(0xFF3B3B98)),
    ('gold', 'Dorado', Color(0xFFFFD700)),
    ('neon', 'Neón', Color(0xFF39FF14)),
  ];

  final ValueNotifier<String> themeMode = ValueNotifier('dark');
  final ValueNotifier<String> colorPalette = ValueNotifier('default');

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = prefs.getString('theme_mode') ?? 'dark';
    colorPalette.value = prefs.getString('color_palette') ?? 'default';
  }

  Future<void> setThemeMode(String mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
  }

  Future<void> setColorPalette(String palette) async {
    colorPalette.value = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_palette', palette);
  }

  /// Obtiene la paleta del agente activo, o null si es un tema normal.
  AgentPalette? get activeAgentPalette {
    final mode = themeMode.value;
    return isAgentMode(mode) ? agentPaletteFromMode(mode) : null;
  }

  /// Color primario: Prioriza el agente activo, luego la paleta de colores, luego el default.
  Color get primaryColor {
    final agent = activeAgentPalette;
    if (agent != null) return agent.primary;

    final id = colorPalette.value;
    for (final t in colorThemes) {
      if (t.$1 == id) return t.$3;
    }
    return defaultColor;
  }
}