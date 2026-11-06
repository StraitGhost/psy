import 'package:flutter/material.dart';

// ───────────────────────── Categorías y rarezas ─────────────────────────

enum AchievementCategory { principal, examenes, conocimiento, desafios, constancia }

extension AchievementCategoryX on AchievementCategory {
  String get label => switch (this) {
        AchievementCategory.principal => 'Principales',
        AchievementCategory.examenes => 'Exámenes',
        AchievementCategory.conocimiento => 'Conocimiento',
        AchievementCategory.desafios => 'Desafíos',
        AchievementCategory.constancia => 'Constancia',
      };

  String get emoji => switch (this) {
        AchievementCategory.principal => '🏆',
        AchievementCategory.examenes => '🎯',
        AchievementCategory.conocimiento => '📚',
        AchievementCategory.desafios => '⚡',
        AchievementCategory.constancia => '🔥',
      };
}

enum Rarity { comun, rara, epica, legendaria }

extension RarityX on Rarity {
  String get label => switch (this) {
        Rarity.comun => 'Común',
        Rarity.rara => 'Rara',
        Rarity.epica => 'Épica',
        Rarity.legendaria => 'Legendaria',
      };

  Color get color => switch (this) {
        Rarity.comun => const Color(0xFF94A3B8),
        Rarity.rara => const Color(0xFF38BDF8),
        Rarity.epica => const Color(0xFFA78BFA),
        Rarity.legendaria => const Color(0xFFFBBF24),
      };

  int get xp => switch (this) {
        Rarity.comun => 20,
        Rarity.rara => 50,
        Rarity.epica => 100,
        Rarity.legendaria => 200,
      };
}

// ───────────────────────── Estadísticas del usuario ─────────────────────────

class UserStats {
  int questionsAnswered;
  int correctAnswers;
  int currentStreak;
  int bestStreak;
  int examsCompleted;
  int perfectExams;
  int perfectExamStreak;
  int bestExamPercent;
  int studyMinutes;
  int modulesCompleted;
  int perfectModules;
  int bestIn5Min;
  int dayStreak;
  String lastVisit;

  // ✅ NUEVO: Los 3 slots de logros destacados
  String featuredSlot1;
  String featuredSlot2;
  String featuredSlot3;

  UserStats({
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.examsCompleted = 0,
    this.perfectExams = 0,
    this.perfectExamStreak = 0,
    this.bestExamPercent = 0,
    this.studyMinutes = 0,
    this.modulesCompleted = 0,
    this.perfectModules = 0,
    this.bestIn5Min = 0,
    this.dayStreak = 0,
    this.lastVisit = '',
    this.featuredSlot1 = '',
    this.featuredSlot2 = '',
    this.featuredSlot3 = '',
  });

  Map<String, dynamic> toJson() => {
        'questionsAnswered': questionsAnswered,
        'correctAnswers': correctAnswers,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'examsCompleted': examsCompleted,
        'perfectExams': perfectExams,
        'perfectExamStreak': perfectExamStreak,
        'bestExamPercent': bestExamPercent,
        'studyMinutes': studyMinutes,
        'modulesCompleted': modulesCompleted,
        'perfectModules': perfectModules,
        'bestIn5Min': bestIn5Min,
        'dayStreak': dayStreak,
        'lastVisit': lastVisit,
        // ✅ NUEVO: Guardado de slots
        'featuredSlot1': featuredSlot1,
        'featuredSlot2': featuredSlot2,
        'featuredSlot3': featuredSlot3,
      };

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        questionsAnswered: j['questionsAnswered'] ?? 0,
        correctAnswers: j['correctAnswers'] ?? 0,
        currentStreak: j['currentStreak'] ?? 0,
        bestStreak: j['bestStreak'] ?? 0,
        examsCompleted: j['examsCompleted'] ?? 0,
        perfectExams: j['perfectExams'] ?? 0,
        perfectExamStreak: j['perfectExamStreak'] ?? 0,
        bestExamPercent: j['bestExamPercent'] ?? 0,
        studyMinutes: j['studyMinutes'] ?? 0,
        modulesCompleted: j['modulesCompleted'] ?? 0,
        perfectModules: j['perfectModules'] ?? 0,
        bestIn5Min: j['bestIn5Min'] ?? 0,
        dayStreak: j['dayStreak'] ?? 0,
        lastVisit: j['lastVisit'] ?? '',
        // ✅ NUEVO: Lectura de slots
        featuredSlot1: j['featuredSlot1'] ?? '',
        featuredSlot2: j['featuredSlot2'] ?? '',
        featuredSlot3: j['featuredSlot3'] ?? '',
      );
}

// ───────────────────────── Definición de logros ─────────────────────────

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;
  final Rarity rarity;
  final int target;
  final num Function(UserStats s) current;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.rarity,
    required this.target,
    required this.current,
  });

  int get xp => rarity.xp;
}

// ───────────────────────── LISTA DE LOGROS ─────────────────────────
const _totalModules = 10;

final List<Achievement> kAchievements = [
  // ── Principales (10) ──
  Achievement(
    id: 'first_step', title: 'Primeros Pasos', description: 'Responde tu primera pregunta',
    icon: Icons.star_rounded, color: const Color(0xFFFFD700),
    category: AchievementCategory.principal, rarity: Rarity.comun, target: 1,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'c_10', title: 'Calentando Motores', description: 'Acierta 10 preguntas',
    icon: Icons.bolt_rounded, color: const Color(0xFFFACC15),
    category: AchievementCategory.principal, rarity: Rarity.comun, target: 10,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'c_25', title: 'En Marcha', description: 'Acierta 25 preguntas',
    icon: Icons.trending_up_rounded, color: const Color(0xFFFB923C),
    category: AchievementCategory.principal, rarity: Rarity.comun, target: 25,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'c_50', title: 'Medio Centenar', description: 'Acierta 50 preguntas',
    icon: Icons.track_changes_rounded, color: const Color(0xFF22C55E),
    category: AchievementCategory.principal, rarity: Rarity.rara, target: 50,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'expert', title: 'Maestro de la Mente', description: 'Alcanza 100 respuestas correctas',
    icon: Icons.psychology_rounded, color: const Color(0xFF8B5CF6),
    category: AchievementCategory.principal, rarity: Rarity.epica, target: 100,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'c_250', title: 'Sabio', description: 'Alcanza 250 respuestas correctas',
    icon: Icons.auto_awesome_rounded, color: const Color(0xFF06B6D4),
    category: AchievementCategory.principal, rarity: Rarity.epica, target: 250,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'champion', title: 'Campeón', description: 'Alcanza 500 respuestas correctas',
    icon: Icons.emoji_events_rounded, color: const Color(0xFFFFB800),
    category: AchievementCategory.principal, rarity: Rarity.legendaria, target: 500,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'c_1000', title: 'Gran Maestro', description: 'Alcanza 1000 respuestas correctas',
    icon: Icons.military_tech_rounded, color: const Color(0xFFEF4444),
    category: AchievementCategory.principal, rarity: Rarity.legendaria, target: 1000,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'c_2500', title: 'Leyenda Viviente', description: 'Alcanza 2500 respuestas correctas',
    icon: Icons.diamond_rounded, color: const Color(0xFFA855F7),
    category: AchievementCategory.principal, rarity: Rarity.legendaria, target: 2500,
    current: (s) => s.correctAnswers,
  ),
  Achievement(
    id: 'fire_streak', title: 'Racha de Fuego', description: 'Responde 5 preguntas seguidas correctamente',
    icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF6B35),
    category: AchievementCategory.principal, rarity: Rarity.comun, target: 5,
    current: (s) => s.bestStreak,
  ),
  // ── Exámenes (18) ──
  Achievement(
    id: 'ex_1', title: 'Hora de Evaluarse', description: 'Completa tu primer examen',
    icon: Icons.assignment_turned_in_rounded, color: const Color(0xFF3B82F6),
    category: AchievementCategory.examenes, rarity: Rarity.comun, target: 1,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'ex_3', title: 'Preparado', description: 'Completa 3 exámenes',
    icon: Icons.assignment_rounded, color: const Color(0xFF0EA5E9),
    category: AchievementCategory.examenes, rarity: Rarity.comun, target: 3,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'ex_5', title: 'Evaluado', description: 'Completa 5 exámenes',
    icon: Icons.task_alt_rounded, color: const Color(0xFF14B8A6),
    category: AchievementCategory.examenes, rarity: Rarity.comun, target: 5,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'ex_10', title: 'Veterano de Exámenes', description: 'Completa 10 exámenes',
    icon: Icons.military_tech_rounded, color: const Color(0xFF6366F1),
    category: AchievementCategory.examenes, rarity: Rarity.rara, target: 10,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'ex_25', title: 'Curtido en Exámenes', description: 'Completa 25 exámenes',
    icon: Icons.checklist_rounded, color: const Color(0xFF8B5CF6),
    category: AchievementCategory.examenes, rarity: Rarity.epica, target: 25,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'ex_50', title: 'Rey de los Exámenes', description: 'Completa 50 exámenes',
    icon: Icons.workspace_premium_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.examenes, rarity: Rarity.legendaria, target: 50,
    current: (s) => s.examsCompleted,
  ),
  Achievement(
    id: 'pe_1', title: 'Mente Brillante', description: 'Acierta el 100% de un examen',
    icon: Icons.verified_rounded, color: const Color(0xFF22C55E),
    category: AchievementCategory.examenes, rarity: Rarity.rara, target: 1,
    current: (s) => s.perfectExams,
  ),
  Achievement(
    id: 'pe_3', title: 'Triple Perfecto', description: 'Acierta el 100% en 3 exámenes',
    icon: Icons.star_half_rounded, color: const Color(0xFF10B981),
    category: AchievementCategory.examenes, rarity: Rarity.epica, target: 3,
    current: (s) => s.perfectExams,
  ),
  Achievement(
    id: 'pe_5', title: 'Impecable', description: 'Acierta el 100% en 5 exámenes',
    icon: Icons.diamond_rounded, color: const Color(0xFF06B6D4),
    category: AchievementCategory.examenes, rarity: Rarity.epica, target: 5,
    current: (s) => s.perfectExams,
  ),
  Achievement(
    id: 'pe_10', title: 'Perfeccionista', description: 'Acierta el 100% en 10 exámenes',
    icon: Icons.gps_fixed_rounded, color: const Color(0xFFEF4444),
    category: AchievementCategory.examenes, rarity: Rarity.legendaria, target: 10,
    current: (s) => s.perfectExams,
  ),
  Achievement(
    id: 'pe_25', title: 'Sin Fallos', description: 'Acierta el 100% en 25 exámenes',
    icon: Icons.grade_rounded, color: const Color(0xFFFBBF24),
    category: AchievementCategory.examenes, rarity: Rarity.legendaria, target: 25,
    current: (s) => s.perfectExams,
  ),
  Achievement(
    id: 'pes_2', title: 'Doble Perfecto', description: 'Logra 100% en 2 exámenes seguidos',
    icon: Icons.looks_two_rounded, color: const Color(0xFFEC4899),
    category: AchievementCategory.examenes, rarity: Rarity.rara, target: 2,
    current: (s) => s.perfectExamStreak,
  ),
  Achievement(
    id: 'pes_3', title: 'Hat-Trick', description: 'Logra 100% en 3 exámenes seguidos',
    icon: Icons.looks_3_rounded, color: const Color(0xFFEC4899),
    category: AchievementCategory.examenes, rarity: Rarity.epica, target: 3,
    current: (s) => s.perfectExamStreak,
  ),
  Achievement(
    id: 'pes_5', title: 'Racha Dorada', description: 'Logra 100% en 5 exámenes seguidos',
    icon: Icons.emoji_events_rounded, color: const Color(0xFFFFD700),
    category: AchievementCategory.examenes, rarity: Rarity.legendaria, target: 5,
    current: (s) => s.perfectExamStreak,
  ),
  Achievement(
    id: 'bx_60', title: 'Aprobado', description: 'Obtén 60% o más en un examen',
    icon: Icons.thumb_up_rounded, color: const Color(0xFF94A3B8),
    category: AchievementCategory.examenes, rarity: Rarity.comun, target: 60,
    current: (s) => s.bestExamPercent,
  ),
  Achievement(
    id: 'bx_75', title: 'Notable', description: 'Obtén 75% o más en un examen',
    icon: Icons.grade_rounded, color: const Color(0xFF38BDF8),
    category: AchievementCategory.examenes, rarity: Rarity.comun, target: 75,
    current: (s) => s.bestExamPercent,
  ),
  Achievement(
    id: 'bx_90', title: 'Sobresaliente', description: 'Obtén 90% o más en un examen',
    icon: Icons.star_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.examenes, rarity: Rarity.rara, target: 90,
    current: (s) => s.bestExamPercent,
  ),
  Achievement(
    id: 'bx_100', title: 'Nota Máxima', description: 'Obtén 100% en un examen',
    icon: Icons.celebration_rounded, color: const Color(0xFF22C55E),
    category: AchievementCategory.examenes, rarity: Rarity.rara, target: 100,
    current: (s) => s.bestExamPercent,
  ),
  // ── Conocimiento (25) ──
  Achievement(
    id: 'q_10', title: 'Curioso', description: 'Responde 10 preguntas',
    icon: Icons.help_rounded, color: const Color(0xFF38BDF8),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 10,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_50', title: 'Explorador', description: 'Responde 50 preguntas',
    icon: Icons.explore_rounded, color: const Color(0xFF14B8A6),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 50,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_100', title: 'Curioso Imparable', description: 'Responde 100 preguntas',
    icon: Icons.quiz_rounded, color: const Color(0xFF14B8A6),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 100,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_250', title: 'Investigador', description: 'Responde 250 preguntas',
    icon: Icons.science_rounded, color: const Color(0xFF6366F1),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 250,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_500', title: 'Analista', description: 'Responde 500 preguntas',
    icon: Icons.fact_check_rounded, color: const Color(0xFF0EA5E9),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 500,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_1000', title: 'Enciclopedia Viviente', description: 'Responde 1000 preguntas',
    icon: Icons.auto_stories_rounded, color: const Color(0xFFA855F7),
    category: AchievementCategory.conocimiento, rarity: Rarity.epica, target: 1000,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_2500', title: 'Biblioteca Andante', description: 'Responde 2500 preguntas',
    icon: Icons.local_library_rounded, color: const Color(0xFFEC4899),
    category: AchievementCategory.conocimiento, rarity: Rarity.legendaria, target: 2500,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'q_5000', title: 'Mente Infinita', description: 'Responde 5000 preguntas',
    icon: Icons.hub_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.conocimiento, rarity: Rarity.legendaria, target: 5000,
    current: (s) => s.questionsAnswered,
  ),
  Achievement(
    id: 'study_15', title: 'Primer Repaso', description: 'Estudia durante 15 minutos',
    icon: Icons.schedule_rounded, color: const Color(0xFF60A5FA),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 15,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_30', title: 'Media Hora', description: 'Estudia durante 30 minutos',
    icon: Icons.timer_rounded, color: const Color(0xFF3B82F6),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 30,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_1h', title: 'Estudiante Dedicado', description: 'Estudia durante 1 hora',
    icon: Icons.menu_book_rounded, color: const Color(0xFF3B82F6),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 60,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_3h', title: 'Maratón de Estudio', description: 'Estudia durante 3 horas',
    icon: Icons.hourglass_bottom_rounded, color: const Color(0xFF0EA5E9),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 180,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_5h', title: 'Cinco Horas', description: 'Estudia durante 5 horas',
    icon: Icons.history_edu_rounded, color: const Color(0xFF6366F1),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 300,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_10h', title: 'Rata de Biblioteca', description: 'Estudia durante 10 horas',
    icon: Icons.school_rounded, color: const Color(0xFF8B5CF6),
    category: AchievementCategory.conocimiento, rarity: Rarity.epica, target: 600,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_25h', title: 'Ermitaño del Saber', description: 'Estudia durante 25 horas',
    icon: Icons.self_improvement_rounded, color: const Color(0xFFD946EF),
    category: AchievementCategory.conocimiento, rarity: Rarity.epica, target: 1500,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'study_50h', title: 'Sabio Eterno', description: 'Estudia durante 50 horas',
    icon: Icons.spa_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.conocimiento, rarity: Rarity.legendaria, target: 3000,
    current: (s) => s.studyMinutes,
  ),
  Achievement(
    id: 'mod_1', title: 'Primer Módulo', description: 'Completa 1 módulo',
    icon: Icons.extension_rounded, color: const Color(0xFF10B981),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 1,
    current: (s) => s.modulesCompleted,
  ),
  Achievement(
    id: 'mod_3', title: 'Tres Áreas', description: 'Completa 3 módulos',
    icon: Icons.layers_rounded, color: const Color(0xFF10B981),
    category: AchievementCategory.conocimiento, rarity: Rarity.comun, target: 3,
    current: (s) => s.modulesCompleted,
  ),
  Achievement(
    id: 'mod_5', title: 'A Medio Camino', description: 'Completa 5 módulos',
    icon: Icons.flag_rounded, color: const Color(0xFF22C55E),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 5,
    current: (s) => s.modulesCompleted,
  ),
  Achievement(
    id: 'mod_7', title: 'Casi Experto', description: 'Completa 7 módulos',
    icon: Icons.category_rounded, color: const Color(0xFF84CC16),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 7,
    current: (s) => s.modulesCompleted,
  ),
  Achievement(
    id: 'scholar', title: 'Erudito', description: 'Completa todos los módulos',
    icon: Icons.workspace_premium_rounded, color: const Color(0xFF10B981),
    category: AchievementCategory.conocimiento, rarity: Rarity.legendaria, target: _totalModules,
    current: (s) => s.modulesCompleted,
  ),
  Achievement(
    id: 'pm_1', title: 'Iluminado', description: 'Obtén 100% de precisión en un módulo',
    icon: Icons.lightbulb_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.conocimiento, rarity: Rarity.rara, target: 1,
    current: (s) => s.perfectModules,
  ),
  Achievement(
    id: 'pm_3', title: 'Mente Lúcida', description: 'Obtén 100% de precisión en 3 módulos',
    icon: Icons.brightness_7_rounded, color: const Color(0xFFFBBF24),
    category: AchievementCategory.conocimiento, rarity: Rarity.epica, target: 3,
    current: (s) => s.perfectModules,
  ),
  Achievement(
    id: 'pm_5', title: 'Brillantez Total', description: 'Obtén 100% de precisión en 5 módulos',
    icon: Icons.wb_sunny_rounded, color: const Color(0xFFF97316),
    category: AchievementCategory.conocimiento, rarity: Rarity.epica, target: 5,
    current: (s) => s.perfectModules,
  ),
  Achievement(
    id: 'pm_10', title: 'Perfección Académica', description: 'Obtén 100% de precisión en 10 módulos',
    icon: Icons.filter_vintage_rounded, color: const Color(0xFFEC4899),
    category: AchievementCategory.conocimiento, rarity: Rarity.legendaria, target: 10,
    current: (s) => s.perfectModules,
  ),
  // ── Desafíos (12) ──
  Achievement(
    id: 'bs_3', title: 'Calentando', description: 'Acierta 3 preguntas seguidas',
    icon: Icons.whatshot_rounded, color: const Color(0xFFFB923C),
    category: AchievementCategory.desafios, rarity: Rarity.comun, target: 3,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'bs_10', title: 'Imparable', description: 'Acierta 10 preguntas seguidas',
    icon: Icons.flash_on_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.desafios, rarity: Rarity.comun, target: 10,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'bs_20', title: 'Perfecto', description: 'Responde 20 preguntas seguidas sin errores',
    icon: Icons.shield_rounded, color: const Color(0xFF14B8A6),
    category: AchievementCategory.desafios, rarity: Rarity.rara, target: 20,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'bs_30', title: 'Inquebrantable', description: 'Responde 30 preguntas seguidas sin errores',
    icon: Icons.security_rounded, color: const Color(0xFF0EA5E9),
    category: AchievementCategory.desafios, rarity: Rarity.epica, target: 30,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'bs_50', title: 'Intocable', description: 'Responde 50 preguntas seguidas sin errores',
    icon: Icons.health_and_safety_rounded, color: const Color(0xFFEF4444),
    category: AchievementCategory.desafios, rarity: Rarity.legendaria, target: 50,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'bs_100', title: 'Invencible', description: 'Responde 100 preguntas seguidas sin errores',
    icon: Icons.rocket_launch_rounded, color: const Color(0xFFA855F7),
    category: AchievementCategory.desafios, rarity: Rarity.legendaria, target: 100,
    current: (s) => s.bestStreak,
  ),
  Achievement(
    id: 'sp_5', title: 'Ágil', description: 'Responde 5 preguntas en 5 minutos',
    icon: Icons.timer_rounded, color: const Color(0xFF38BDF8),
    category: AchievementCategory.desafios, rarity: Rarity.comun, target: 5,
    current: (s) => s.bestIn5Min,
  ),
  Achievement(
    id: 'sp_10', title: 'Velocista', description: 'Responde 10 preguntas en 5 minutos',
    icon: Icons.speed_rounded, color: const Color(0xFFEC4899),
    category: AchievementCategory.desafios, rarity: Rarity.comun, target: 10,
    current: (s) => s.bestIn5Min,
  ),
  Achievement(
    id: 'sp_15', title: 'Veloz', description: 'Responde 15 preguntas en 5 minutos',
    icon: Icons.directions_run_rounded, color: const Color(0xFFF97316),
    category: AchievementCategory.desafios, rarity: Rarity.rara, target: 15,
    current: (s) => s.bestIn5Min,
  ),
  Achievement(
    id: 'sp_25', title: 'Rayo', description: 'Responde 25 preguntas en 5 minutos',
    icon: Icons.bolt_rounded, color: const Color(0xFFFACC15),
    category: AchievementCategory.desafios, rarity: Rarity.epica, target: 25,
    current: (s) => s.bestIn5Min,
  ),
  Achievement(
    id: 'sp_40', title: 'Relámpago', description: 'Responde 40 preguntas en 5 minutos',
    icon: Icons.electric_bolt_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.desafios, rarity: Rarity.epica, target: 40,
    current: (s) => s.bestIn5Min,
  ),
  Achievement(
    id: 'sp_60', title: 'Velocidad Luz', description: 'Responde 60 preguntas en 5 minutos',
    icon: Icons.sports_score_rounded, color: const Color(0xFFD946EF),
    category: AchievementCategory.desafios, rarity: Rarity.legendaria, target: 60,
    current: (s) => s.bestIn5Min,
  ),
  // ── Constancia (12) ──
  Achievement(
    id: 'd_2', title: 'Vuelves por Más', description: 'Entra 2 días seguidos',
    icon: Icons.event_available_rounded, color: const Color(0xFFFDBA74),
    category: AchievementCategory.constancia, rarity: Rarity.comun, target: 2,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'day_3', title: 'Buen Hábito', description: 'Entra 3 días seguidos',
    icon: Icons.calendar_today_rounded, color: const Color(0xFFFB923C),
    category: AchievementCategory.constancia, rarity: Rarity.comun, target: 3,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_5', title: 'Cinco Seguidos', description: 'Entra 5 días seguidos',
    icon: Icons.favorite_rounded, color: const Color(0xFFF43F5E),
    category: AchievementCategory.constancia, rarity: Rarity.comun, target: 5,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'day_7', title: 'Semana Perfecta', description: 'Entra 7 días seguidos',
    icon: Icons.date_range_rounded, color: const Color(0xFFF97316),
    category: AchievementCategory.constancia, rarity: Rarity.rara, target: 7,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_10', title: 'Diez Días', description: 'Entra 10 días seguidos',
    icon: Icons.park_rounded, color: const Color(0xFF84CC16),
    category: AchievementCategory.constancia, rarity: Rarity.rara, target: 10,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_14', title: 'Quincena', description: 'Entra 14 días seguidos',
    icon: Icons.landscape_rounded, color: const Color(0xFF22C55E),
    category: AchievementCategory.constancia, rarity: Rarity.rara, target: 14,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_21', title: 'Hábito Formado', description: 'Entra 21 días seguidos',
    icon: Icons.key_rounded, color: const Color(0xFF8B5CF6),
    category: AchievementCategory.constancia, rarity: Rarity.epica, target: 21,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_30', title: 'Leyenda Constante', description: 'Entra 30 días seguidos',
    icon: Icons.whatshot_rounded, color: const Color(0xFFDC2626),
    category: AchievementCategory.constancia, rarity: Rarity.epica, target: 30,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_60', title: 'Dos Meses', description: 'Entra 60 días seguidos',
    icon: Icons.nightlight_round, color: const Color(0xFF6366F1),
    category: AchievementCategory.constancia, rarity: Rarity.epica, target: 60,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_100', title: 'Centenario', description: 'Entra 100 días seguidos',
    icon: Icons.emoji_events_rounded, color: const Color(0xFFF59E0B),
    category: AchievementCategory.constancia, rarity: Rarity.legendaria, target: 100,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_180', title: 'Medio Año', description: 'Entra 180 días seguidos',
    icon: Icons.diamond_rounded, color: const Color(0xFF06B6D4),
    category: AchievementCategory.constancia, rarity: Rarity.legendaria, target: 180,
    current: (s) => s.dayStreak,
  ),
  Achievement(
    id: 'd_365', title: 'Un Año Entero', description: 'Entra 365 días seguidos',
    icon: Icons.rocket_launch_rounded, color: const Color(0xFFA855F7),
    category: AchievementCategory.constancia, rarity: Rarity.legendaria, target: 365,
    current: (s) => s.dayStreak,
  ),
];

// ───────────────────────── Función Helper ─────────────────────────
/// Busca un logro por su ID de forma segura (evita errores en home_screen.dart)
Achievement? getAchievementById(String id) {
  try {
    return kAchievements.firstWhere((a) => a.id == id);
  } catch (e) {
    return null;
  }
}