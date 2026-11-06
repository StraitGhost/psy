// lib/core/theme/agent_theme.dart
import 'package:flutter/material.dart';

/// Los temas de agentes viven en el mismo valor que 'light' / 'dark' / 'system'.
/// Ejemplo: themeMode.value = 'agent:jett'
const String kAgentPrefix = 'agent:';

bool isAgentMode(String mode) => mode.startsWith(kAgentPrefix);

// ─────────────────────────────────────────────────────────────
// Paleta COMPLETA de un agente
// Cada agente ahora tiene TODOS sus colores definidos explícitamente
// ─────────────────────────────────────────────────────────────
class AgentPalette {
  final String id;
  final String name;
  
  // Colores principales de identidad
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color tertiary;
  
  // Superficies y fondos (oscuros pero con el tinte del agente)
  final Color background;
  final Color backgroundSecondary;
  final Color surface;
  final Color surfaceCard;
  final Color surfaceElevated;
  
  // Sidebar y navegación
  final Color sidebarBg;
  final Color sidebarItem;
  final Color sidebarItemActive;
  
  // Bordes y divisiones
  final Color border;
  final Color borderLight;
  final Color borderAccent;
  
  // Estados y feedback
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  
  // Texto
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnPrimary;
  final Color textOnSecondary;

  const AgentPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    this.accent = const Color(0xFFFFFFFF),
    this.tertiary = const Color(0xFF1E293B),
    required this.background,
    this.backgroundSecondary = const Color(0xFF0F172A),
    required this.surface,
    required this.surfaceCard,
    this.surfaceElevated = const Color(0xFF1E293B),
    required this.sidebarBg,
    required this.sidebarItem,
    this.sidebarItemActive = const Color(0xFF334155),
    required this.border,
    this.borderLight = const Color(0xFF334155),
    this.borderAccent = const Color(0xFF475569),
    this.success = const Color(0xFF10B981),
    this.error = const Color(0xFFEF4444),
    this.warning = const Color(0xFFF59E0B),
    this.info = const Color(0xFF3B82F6),
    this.textPrimary = const Color(0xFFF8FAFC),
    this.textSecondary = const Color(0xFF94A3B8),
    this.textMuted = const Color(0xFF64748B),
    this.textOnPrimary = const Color(0xFF0F172A),
    this.textOnSecondary = const Color(0xFFF8FAFC),
  });

  /// Texto legible sobre un color de relleno
  Color on(Color c) => ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? Colors.white
      : const Color(0xFF0B0F1A);

  /// Gradiente principal del agente
  LinearGradient get gradient => LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Gradiente suave para fondos
  LinearGradient get gradientSubtle => LinearGradient(
        colors: [background, backgroundSecondary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}

// ─────────────────────────────────────────────────────────────
// PALETAS COMPLETAS POR AGENTE
// Basadas en los colores oficiales de Valorant [[1]][[3]][[9]]
// ─────────────────────────────────────────────────────────────
const agentPalettes = <AgentPalette>[
  // JETT - Azul cian/cielo [[9]]
  AgentPalette(
    id: 'jett',
    name: 'Jett',
    primary: Color(0xFF73F5ED),      // Cian brillante
    secondary: Color(0xFF435680),    // Azul grisáceo
    accent: Color(0xFF77D4E4),       // Cian medio
    tertiary: Color(0xFF0B0E22),     // Azul muy oscuro
    background: Color(0xFF0A0E1A),   // Fondo principal
    backgroundSecondary: Color(0xFF0F1525),
    surface: Color(0xFF151E32),      // Superficie
    surfaceCard: Color(0xFF1E2947),  // Tarjetas
    sidebarBg: Color(0xFF0D1221),    // Sidebar
    sidebarItem: Color(0xFF1A2339),
    border: Color(0xFF2A3554),
    borderLight: Color(0xFF1E2947),
    borderAccent: Color(0xFF73F5ED),
  ),

  // REYNA - Púrpura/violeta
  AgentPalette(
    id: 'reyna',
    name: 'Reyna',
    primary: Color(0xFF8E44AD),      // Púrpura intenso
    secondary: Color(0xFFC39BD3),    // Lavanda
    accent: Color(0xFF6C3483),       // Púrpura oscuro
    tertiary: Color(0xFF1A0D24),
    background: Color(0xFF0F0814),
    backgroundSecondary: Color(0xFF150A1F),
    surface: Color(0xFF1E0F2E),
    surfaceCard: Color(0xFF2D1B4E),
    sidebarBg: Color(0xFF12081A),
    sidebarItem: Color(0xFF231133),
    border: Color(0xFF3D2857),
    borderLight: Color(0xFF2D1B4E),
    borderAccent: Color(0xFF8E44AD),
  ),

  // PHOENIX - Naranja/fuego
  AgentPalette(
    id: 'phoenix',
    name: 'Phoenix',
    primary: Color(0xFFFF5F1F),      // Naranja fuego
    secondary: Color(0xFFFF9F43),    // Naranja claro
    accent: Color(0xFFFFD93D),       // Amarillo
    tertiary: Color(0xFF2D1008),
    background: Color(0xFF1A0C06),
    backgroundSecondary: Color(0xFF241109),
    surface: Color(0xFF2E1509),
    surfaceCard: Color(0xFF3D1F0D),
    sidebarBg: Color(0xFF1F0D07),
    sidebarItem: Color(0xFF331609),
    border: Color(0xFF572916),
    borderLight: Color(0xFF3D1F0D),
    borderAccent: Color(0xFFFF5F1F),
  ),

  // SAGE - Verde azulado/turquesa
  AgentPalette(
    id: 'sage',
    name: 'Sage',
    primary: Color(0xFF3BE0C3),      // Turquesa
    secondary: Color(0xFF16B199),    // Verde azulado
    accent: Color(0xFF7FFFD4),       // Aqua
    tertiary: Color(0xFF0A2620),
    background: Color(0xFF061412),
    backgroundSecondary: Color(0xFF091E1A),
    surface: Color(0xFF0D2924),
    surfaceCard: Color(0xFF143D36),
    sidebarBg: Color(0xFF081A16),
    sidebarItem: Color(0xFF0F2E28),
    border: Color(0xFF1F5248),
    borderLight: Color(0xFF143D36),
    borderAccent: Color(0xFF3BE0C3),
  ),

  // RAZE - Naranja/verde explosivo
  AgentPalette(
    id: 'raze',
    name: 'Raze',
    primary: Color(0xFFFF7F00),      // Naranja
    secondary: Color(0xFF7FFF00),    // Verde lima
    accent: Color(0xFFFFB84D),       // Naranja claro
    tertiary: Color(0xFF1A2400),
    background: Color(0xFF141206),
    backgroundSecondary: Color(0xFF1E1B09),
    surface: Color(0xFF292409),
    surfaceCard: Color(0xFF3D330D),
    sidebarBg: Color(0xFF1A1607),
    sidebarItem: Color(0xFF2E280A),
    border: Color(0xFF524816),
    borderLight: Color(0xFF3D330D),
    borderAccent: Color(0xFFFF7F00),
  ),

  // SOVA - Azul eléctrico
  AgentPalette(
    id: 'sova',
    name: 'Sova',
    primary: Color(0xFF1E90FF),      // Azul brillante
    secondary: Color(0xFF00BFFF),    // DeepSkyBlue
    accent: Color(0xFF4169E1),       // RoyalBlue
    tertiary: Color(0xFF0A1624),
    background: Color(0xFF060E14),
    backgroundSecondary: Color(0xFF09151E),
    surface: Color(0xFF0D1E29),
    surfaceCard: Color(0xFF142D3D),
    sidebarBg: Color(0xFF08111A),
    sidebarItem: Color(0xFF0F202E),
    border: Color(0xFF1F3D57),
    borderLight: Color(0xFF142D3D),
    borderAccent: Color(0xFF1E90FF),
  ),

  // VIPER - Verde neón
  AgentPalette(
    id: 'viper',
    name: 'Viper',
    primary: Color(0xFF39FF14),      // Verde neón
    secondary: Color(0xFF00FF7F),    // SpringGreen
    accent: Color(0xFF7FFF00),       // Chartreuse
    tertiary: Color(0xFF0A1406),
    background: Color(0xFF061408),
    backgroundSecondary: Color(0xFF091E0C),
    surface: Color(0xFF0D2910),
    surfaceCard: Color(0xFF143D18),
    sidebarBg: Color(0xFF081A0A),
    sidebarItem: Color(0xFF0F2E12),
    border: Color(0xFF1F5224),
    borderLight: Color(0xFF143D18),
    borderAccent: Color(0xFF39FF14),
  ),

  // OMEN - Púrpura oscuro
  AgentPalette(
    id: 'omen',
    name: 'Omen',
    primary: Color(0xFF5D4A7D),      // Púrpura oscuro
    secondary: Color(0xFF7B68A8),    // Lavanda oscuro
    accent: Color(0xFF9370DB),       // MediumPurple
    tertiary: Color(0xFF140F1E),
    background: Color(0xFF0C0814),
    backgroundSecondary: Color(0xFF120D1E),
    surface: Color(0xFF1A1229),
    surfaceCard: Color(0xFF291A3D),
    sidebarBg: Color(0xFF0F0A1A),
    sidebarItem: Color(0xFF1E122E),
    border: Color(0xFF3D2857),
    borderLight: Color(0xFF291A3D),
    borderAccent: Color(0xFF5D4A7D),
  ),

  // KAY/O - Naranja/azul robótico
  AgentPalette(
    id: 'kayo',
    name: 'KAY/O',
    primary: Color(0xFFFF6B00),      // Naranja
    secondary: Color(0xFF2F4FFF),    // Azul eléctrico
    accent: Color(0xFFBA75FF),       // Púrpura claro
    tertiary: Color(0xFF1A1424),
    background: Color(0xFF0A0814),
    backgroundSecondary: Color(0xFF0F0D1E),
    surface: Color(0xFF1A1229),
    surfaceCard: Color(0xFF291A3D),
    sidebarBg: Color(0xFF0D0A1A),
    sidebarItem: Color(0xFF1E122E),
    border: Color(0xFF3D2857),
    borderLight: Color(0xFF291A3D),
    borderAccent: Color(0xFFFF6B00),
  ),

  // NEON - Cian/magenta neón
  AgentPalette(
    id: 'neon',
    name: 'Neon',
    primary: Color(0xFF00D4FF),      // Cian neón
    secondary: Color(0xFFFF00FF),    // Magenta
    accent: Color(0xFF00FFFF),       // Cyan
    tertiary: Color(0xFF140A1E),
    background: Color(0xFF0A0614),
    backgroundSecondary: Color(0xFF0F091E),
    surface: Color(0xFF1A0F29),
    surfaceCard: Color(0xFF29163D),
    sidebarBg: Color(0xFF0D081A),
    sidebarItem: Color(0xFF1E0F2E),
    border: Color(0xFF3D1E57),
    borderLight: Color(0xFF29163D),
    borderAccent: Color(0xFF00D4FF),
  ),

  // KILLJOY - Amarillo/dorado
  AgentPalette(
    id: 'killjoy',
    name: 'Killjoy',
    primary: Color(0xFFFFD200),      // Amarillo
    secondary: Color(0xFFFF9500),    // Naranja dorado
    accent: Color(0xFFFFE44D),       // Amarillo claro
    tertiary: Color(0xFF241A06),
    background: Color(0xFF141006),
    backgroundSecondary: Color(0xFF1E1809),
    surface: Color(0xFF292109),
    surfaceCard: Color(0xFF3D310D),
    sidebarBg: Color(0xFF1A1407),
    sidebarItem: Color(0xFF2E260A),
    border: Color(0xFF524516),
    borderLight: Color(0xFF3D310D),
    borderAccent: Color(0xFFFFD200),
  ),

  // CYPER - Azul tecnológico
  AgentPalette(
    id: 'cypher',
    name: 'Cypher',
    primary: Color(0xFF4B9CD3),      // Azul
    secondary: Color(0xFF7BB8E0),    // Azul claro
    accent: Color(0xFF1E90FF),       // DodgerBlue
    tertiary: Color(0xFF0A1624),
    background: Color(0xFF060E14),
    backgroundSecondary: Color(0xFF09151E),
    surface: Color(0xFF0D1E29),
    surfaceCard: Color(0xFF142D3D),
    sidebarBg: Color(0xFF08111A),
    sidebarItem: Color(0xFF0F202E),
    border: Color(0xFF1F3D57),
    borderLight: Color(0xFF142D3D),
    borderAccent: Color(0xFF4B9CD3),
  ),

  // ASTRA - Púrpura cósmico
  AgentPalette(
    id: 'astra',
    name: 'Astra',
    primary: Color(0xFF9D7CD8),      // Púrpura
    secondary: Color(0xFFB89CE8),    // Lavanda
    accent: Color(0xFF7B68EE),       // MediumSlateBlue
    tertiary: Color(0xFF140F24),
    background: Color(0xFF0C0814),
    backgroundSecondary: Color(0xFF120D1E),
    surface: Color(0xFF1A1229),
    surfaceCard: Color(0xFF291A3D),
    sidebarBg: Color(0xFF0F0A1A),
    sidebarItem: Color(0xFF1E122E),
    border: Color(0xFF3D2857),
    borderLight: Color(0xFF291A3D),
    borderAccent: Color(0xFF9D7CD8),
  ),

  // BREACH - Naranja rojizo
  AgentPalette(
    id: 'breach',
    name: 'Breach',
    primary: Color(0xFFF38341),      // Naranja
    secondary: Color(0xFFFF6B35),    // Naranja rojizo
    accent: Color(0xFFFFA07A),       // LightSalmon
    tertiary: Color(0xFF241408),
    background: Color(0xFF140C06),
    backgroundSecondary: Color(0xFF1E1309),
    surface: Color(0xFF291A09),
    surfaceCard: Color(0xFF3D260D),
    sidebarBg: Color(0xFF1A0F07),
    sidebarItem: Color(0xFF2E1A0A),
    border: Color(0xFF573316),
    borderLight: Color(0xFF3D260D),
    borderAccent: Color(0xFFF38341),
  ),

  // BRIMSTONE - Rojo
  AgentPalette(
    id: 'brimstone',
    name: 'Brimstone',
    primary: Color(0xFFF95B41),      // Rojo coral
    secondary: Color(0xFFFF725C),    // Rojo claro
    accent: Color(0xFFDC143C),       // Crimson
    tertiary: Color(0xFF240A08),
    background: Color(0xFF140806),
    backgroundSecondary: Color(0xFF1E0C09),
    surface: Color(0xFF291009),
    surfaceCard: Color(0xFF3D180D),
    sidebarBg: Color(0xFF1A0A07),
    sidebarItem: Color(0xFF2E120A),
    border: Color(0xFF572216),
    borderLight: Color(0xFF3D180D),
    borderAccent: Color(0xFFF95B41),
  ),

  // CHAMBER - Dorado/champán
  AgentPalette(
    id: 'chamber',
    name: 'Chamber',
    primary: Color(0xFFC6A665),      // Dorado
    secondary: Color(0xFFD4B978),    // Oro claro
    accent: Color(0xFFB8956A),       // Oro viejo
    tertiary: Color(0xFF1E1810),
    background: Color(0xFF14100A),
    backgroundSecondary: Color(0xFF1E1810),
    surface: Color(0xFF292114),
    surfaceCard: Color(0xFF3D311E),
    sidebarBg: Color(0xFF1A140D),
    sidebarItem: Color(0xFF2E2618),
    border: Color(0xFF524529),
    borderLight: Color(0xFF3D311E),
    borderAccent: Color(0xFFC6A665),
  ),

  // CLOVE - Rosa/morado
  AgentPalette(
    id: 'clove',
    name: 'Clove',
    primary: Color(0xFFE65AAE),      // Rosa
    secondary: Color(0xFF7A3CFF),    // Púrpura
    accent: Color(0xFFFF69B4),       // HotPink
    tertiary: Color(0xFF1E0A14),
    background: Color(0xFF14060E),
    backgroundSecondary: Color(0xFF1E0915),
    surface: Color(0xFF290D1E),
    surfaceCard: Color(0xFF3D142E),
    sidebarBg: Color(0xFF1A0812),
    sidebarItem: Color(0xFF2E0F20),
    border: Color(0xFF571E3D),
    borderLight: Color(0xFF3D142E),
    borderAccent: Color(0xFFE65AAE),
  ),

  // DEADLOCK - Azul grisáceo
  AgentPalette(
    id: 'deadlock',
    name: 'Deadlock',
    primary: Color(0xFF1F2C5C),      // Azul oscuro
    secondary: Color(0xFF6E7EA8),    // Azul gris
    accent: Color(0xFF4169E1),       // RoyalBlue
    tertiary: Color(0xFF0A0E14),
    background: Color(0xFF060814),
    backgroundSecondary: Color(0xFF090D1E),
    surface: Color(0xFF0D1229),
    surfaceCard: Color(0xFF141A3D),
    sidebarBg: Color(0xFF080A1A),
    sidebarItem: Color(0xFF0F142E),
    border: Color(0xFF1F2657),
    borderLight: Color(0xFF141A3D),
    borderAccent: Color(0xFF1F2C5C),
  ),

  // FADE - Gris púrpura
  AgentPalette(
    id: 'fade',
    name: 'Fade',
    primary: Color(0xFF4A4E69),      // Gris púrpura
    secondary: Color(0xFF6B6E8A),    // Gris azulado
    accent: Color(0xFF9A8C98),       // Gris lavanda
    tertiary: Color(0xFF14121E),
    background: Color(0xFF0C0A14),
    backgroundSecondary: Color(0xFF120F1E),
    surface: Color(0xFF1A1629),
    surfaceCard: Color(0xFF29213D),
    sidebarBg: Color(0xFF0F0D1A),
    sidebarItem: Color(0xFF1E182E),
    border: Color(0xFF3D3157),
    borderLight: Color(0xFF29213D),
    borderAccent: Color(0xFF4A4E69),
  ),

  // GEKKO - Verde lima
  AgentPalette(
    id: 'gekko',
    name: 'Gekko',
    primary: Color(0xFF8AC926),      // Verde lima
    secondary: Color(0xFFA8E063),    // Verde claro
    accent: Color(0xFF6AB04C),       // Verde
    tertiary: Color(0xFF141E06),
    background: Color(0xFF0C1406),
    backgroundSecondary: Color(0xFF121E09),
    surface: Color(0xFF1A290D),
    surfaceCard: Color(0xFF293D14),
    sidebarBg: Color(0xFF0F1A07),
    sidebarItem: Color(0xFF1E2E0F),
    border: Color(0xFF3D571F),
    borderLight: Color(0xFF293D14),
    borderAccent: Color(0xFF8AC926),
  ),

  // HARBOR - Azul océano
  AgentPalette(
    id: 'harbor',
    name: 'Harbor',
    primary: Color(0xFF0077B6),      // Azul océano
    secondary: Color(0xFF00B4D8),    // Azul claro
    accent: Color(0xFF48CAE4),       // Cyan
    tertiary: Color(0xFF0A141E),
    background: Color(0xFF060E14),
    backgroundSecondary: Color(0xFF09151E),
    surface: Color(0xFF0D1E29),
    surfaceCard: Color(0xFF142D3D),
    sidebarBg: Color(0xFF08111A),
    sidebarItem: Color(0xFF0F202E),
    border: Color(0xFF1F3D57),
    borderLight: Color(0xFF142D3D),
    borderAccent: Color(0xFF0077B6),
  ),

  // ISO - Cian/amarillo
  AgentPalette(
    id: 'iso',
    name: 'Iso',
    primary: Color(0xFF00E5FF),      // Cian
    secondary: Color(0xFFF4D03F),    // Amarillo
    accent: Color(0xFF00D2FF),       // Cyan
    tertiary: Color(0xFF0A141E),
    background: Color(0xFF060E14),
    backgroundSecondary: Color(0xFF09151E),
    surface: Color(0xFF0D1E29),
    surfaceCard: Color(0xFF142D3D),
    sidebarBg: Color(0xFF08111A),
    sidebarItem: Color(0xFF0F202E),
    border: Color(0xFF1F3D57),
    borderLight: Color(0xFF142D3D),
    borderAccent: Color(0xFF00E5FF),
  ),

  // SKYE - Verde naturaleza
  AgentPalette(
    id: 'skye',
    name: 'Skye',
    primary: Color(0xFF4CAF50),      // Verde
    secondary: Color(0xFF66BB6A),    // Verde claro
    accent: Color(0xFF81C784),       // Verde pálido
    tertiary: Color(0xFF0A1408),
    background: Color(0xFF061408),
    backgroundSecondary: Color(0xFF091E0C),
    surface: Color(0xFF0D2910),
    surfaceCard: Color(0xFF143D18),
    sidebarBg: Color(0xFF081A0A),
    sidebarItem: Color(0xFF0F2E12),
    border: Color(0xFF1F5224),
    borderLight: Color(0xFF143D18),
    borderAccent: Color(0xFF4CAF50),
  ),

  // VYSE - Gris/púrpura tecnológico
  AgentPalette(
    id: 'vyse',
    name: 'Vyse',
    primary: Color(0xFF7C5CFF),      // Púrpura
    secondary: Color(0xFF9D8BFF),    // Lavanda
    accent: Color(0xFF5D44CC),       // Púrpura oscuro
    tertiary: Color(0xFF0E0F12),
    background: Color(0xFF0A0B0E),
    backgroundSecondary: Color(0xFF0F1014),
    surface: Color(0xFF14151A),
    surfaceCard: Color(0xFF1E1F26),
    sidebarBg: Color(0xFF0C0D10),
    sidebarItem: Color(0xFF16171C),
    border: Color(0xFF2A2B33),
    borderLight: Color(0xFF1E1F26),
    borderAccent: Color(0xFF7C5CFF),
  ),

  // YORU - Azul índigo
  AgentPalette(
    id: 'yoru',
    name: 'Yoru',
    primary: Color(0xFF1A237E),      // Índigo
    secondary: Color(0xFF283593),    // Azul profundo
    accent: Color(0xFF3949AB),       // Indigo
    tertiary: Color(0xFF0A0C14),
    background: Color(0xFF060814),
    backgroundSecondary: Color(0xFF090D1E),
    surface: Color(0xFF0D1229),
    surfaceCard: Color(0xFF141A3D),
    sidebarBg: Color(0xFF080A1A),
    sidebarItem: Color(0xFF0F142E),
    border: Color(0xFF1F2657),
    borderLight: Color(0xFF141A3D),
    borderAccent: Color(0xFF1A237E),
  ),
];

/// 'agent:jett' → paleta de Jett. Cualquier otro valor → null.
AgentPalette? agentPaletteFromMode(String mode) {
  if (!isAgentMode(mode)) return null;
  final id = mode.substring(kAgentPrefix.length);
  for (final p in agentPalettes) {
    if (p.id == id) return p;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// Extensiones útiles
// ─────────────────────────────────────────────────────────────
extension AgentPaletteExtensions on AgentPalette {
  /// Obtiene el modo del tema para este agente
  String get mode => '$kAgentPrefix$id';

  /// Verifica si un color es parte de la paleta principal
  bool isPrimaryColor(Color color) {
    return color.value == primary.value ||
           color.value == secondary.value ||
           color.value == accent.value;
  }

  /// Crea un esquema de color de Material
  ColorScheme toColorScheme() {
    return ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      error: error,
      onPrimary: textOnPrimary,
      onSecondary: textOnSecondary,
      onSurface: textPrimary,
      onError: textOnPrimary,
    );
  }
}