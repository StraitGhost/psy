import 'package:flutter/material.dart';

/// Helper de opacidad que funciona en cualquier versión de Flutter
/// (evita el aviso de `withOpacity` deprecado).
extension ColorOpacityX on Color {
  Color o(double opacity) =>
      withAlpha((opacity * 255).round().clamp(0, 255).toInt());
}

/// Paleta del diseño "Casos Clínicos" (azul noche + acentos violeta/turquesa).
class GameColors {
  GameColors._();

  static const background = Color(0xFF040A1C);
  static const backgroundTop = Color(0xFF071230);

  static const panelTop = Color(0xFF0E2260);
  static const panelBottom = Color(0xFF081543);
  static const panelBorder = Color(0xFF203C94);
  static const field = Color(0xFF0A1A50);

  static const glow = Color(0xFF3E6BFF);
  static const accent = Color(0xFF8B5CF6);
  static const accentDeep = Color(0xFF4C2FB5);
  static const cyan = Color(0xFF2DD4EF);

  static const success = Color(0xFF16C79A);
  static const successDeep = Color(0xFF0A5F62);
  static const danger = Color(0xFFFF5C8A);
  static const gold = Color(0xFFFFC53D);

  static const textMuted = Color(0xFF9FB2E8);

  static const screenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, background],
  );

  static const panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [panelTop, panelBottom],
  );
}
