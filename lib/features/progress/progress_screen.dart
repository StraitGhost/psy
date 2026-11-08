// lib/features/progress/progress_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_preferences.dart';
import '../../models/profile.dart';
import '../../services/profile_data_service.dart';
import '../../services/streak_service.dart';

// ─────────────────────────────────────────────────────────────
// Colores FIJOS de logros y rachas (NO cambian con el agente)
// ─────────────────────────────────────────────────────────────
class _Achievement {
  static const orange = Color(0xFFFF6B35);
  static const gold = Color(0xFFFFD43B);
}

TextStyle _t(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c, height: height);

// ─────────────────────────────────────────────────────────────
// Datos fijos
// ─────────────────────────────────────────────────────────────
class _Topic {
  final String name;
  final IconData icon;
  final Color color;
  const _Topic(this.name, this.icon, this.color);
}

const _topics = <_Topic>[
  _Topic('Conciencia', Icons.wb_sunny, Color(0xFF00B4DB)),
  _Topic('Orientación', Icons.explore, Color(0xFF11998E)),
  _Topic('Atención', Icons.center_focus_weak, Color(0xFFFF512F)),
  _Topic('Memoria', Icons.memory, Color(0xFF8E2DE2)),
  _Topic('Percepción', Icons.visibility, Color(0xFF00C6FF)),
  _Topic('Pensamiento', Icons.psychology, Color(0xFFDA22FF)),
  _Topic('Sueño', Icons.nightlight_round, Color(0xFF2193B0)),
  _Topic('Apetito', Icons.restaurant, Color(0xFF56AB2F)),
  _Topic('Sexualidad', Icons.favorite, Color(0xFFFF9A9E)),
  _Topic('Síndromes', Icons.medical_services, Color(0xFF536976)),
];

const _levelNames = [
  'Principiante',
  'Intermedio',
  'Avanzado',
  'Experto',
  'Experto Avanzado',
  'Maestro',
];

const _levelThresholds = [0.0, 0.50, 0.60, 0.70, 0.80, 0.95];
const _dailyGoal = 10;

int _asInt(dynamic v) =>
    v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

Map<String, double> _parseMastery(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((k, v) =>
      MapEntry(k.toString(), _asDouble(v).clamp(0.0, 1.0).toDouble()));
}

class _Data {
  final int correct, wrong, xp, streak, bestStreak;
  final Map<String, double> mastery;
  final Map<String, int> daily;

  const _Data({
    required this.correct,
    required this.wrong,
    required this.xp,
    required this.streak,
    required this.bestStreak,
    required this.mastery,
    required this.daily,
  });

  /// [m] es el documento usuarios/{uid}/perfiles/{profileId}
  factory _Data.fromMap(Map<String, dynamic> m) {
    // Racha real del perfil (0 si se rompió y no tiene protectores)
    final streak = StreakService.displayStreak(m);

    final rawDaily = m['dailyActivity'];
    final daily = <String, int>{};
    if (rawDaily is Map) {
      rawDaily.forEach((k, v) => daily[k.toString()] = _asInt(v));
    }

    return _Data(
      correct: _asInt(m['correctAnswers']),
      wrong: _asInt(m['wrongAnswers']),
      xp: _asInt(m['xp']),
      streak: streak,
      bestStreak: math.max(_asInt(m['bestStreak']), streak),
      mastery: _parseMastery(m['topicMastery']),
      daily: daily,
    );
  }

  int get total => correct + wrong;
  double get accuracy => total > 0 ? correct / total : 0.0;

  int get level {
    var l = 0;
    for (var i = 0; i < _levelThresholds.length; i++) {
      if (accuracy >= _levelThresholds[i]) l = i;
    }
    return l;
  }

  bool get isMax => level == _levelNames.length - 1;

  double get progressToNext => isMax
      ? 1.0
      : ((accuracy - _levelThresholds[level]) /
              (_levelThresholds[level + 1] - _levelThresholds[level]))
          .clamp(0.0, 1.0);
}

// ─────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────
class ProgressScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ProgressScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    // Datos de ESTE perfil: usuarios/{uid}/perfiles/{profileId}
    final ref = ProfileDataService.refFor(userProfile.id);

    return ValueListenableBuilder<String>(
      valueListenable: ThemePreferences.instance.themeMode,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.surface],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: ref == null
                        ? _buildMessage(
                            Icons.lock_outline_rounded,
                            'No hay usuario logueado',
                            'Inicia sesión para ver tu progreso.')
                        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: ref.snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return _buildMessage(
                                  Icons.cloud_off_rounded,
                                  'No pudimos cargar tus datos',
                                  'Revisa tu conexión e inténtalo de nuevo.',
                                );
                              }
                              if (!snap.hasData) {
                                return Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                );
                              }
                              if (!snap.data!.exists) {
                                return _buildMessage(
                                  Icons.analytics_outlined,
                                  'Aún no hay datos',
                                  'Responde algunas preguntas para ver tu progreso aquí.',
                                );
                              }
                              final map =
                                  snap.data!.data() ?? <String, dynamic>{};
                              final d = _Data.fromMap(map);
                              return LayoutBuilder(
                                builder: (_, c) =>
                                    _buildDashboard(d, c.maxWidth),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu progreso',
                    style: _t(22, FontWeight.w800, AppColors.textPrimary)),
                Text('Responde, aprende y mejora',
                    style: _t(12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: AppColors.accent, size: 54),
            ),
            const SizedBox(height: 22),
            Text(title,
                textAlign: TextAlign.center,
                style: _t(21, FontWeight.w800, AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: _t(14, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(_Data d, double width) {
    final wide = width >= 900;
    const gap = SizedBox(height: 16);

    final Widget content = wide
        ? Column(
            children: [
              _buildHero(d, wide: true),
              gap,
              _buildStats(d, wide: true),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(children: [
                      _buildInsights(d),
                      gap,
                      _buildWeekly(d),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: Column(children: [
                      _buildTopics(d, wide: true),
                      gap,
                      _buildStreaks(d),
                    ]),
                  ),
                ],
              ),
              gap,
              _buildMotto(),
            ],
          )
        : Column(
            children: [
              _buildHero(d, wide: false),
              gap,
              _buildStats(d, wide: false),
              gap,
              _buildInsights(d),
              gap,
              _buildTopics(d, wide: false),
              gap,
              _buildWeekly(d),
              gap,
              _buildStreaks(d),
              gap,
              _buildMotto(),
            ],
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHero(_Data d, {required bool wide}) {
    final level = d.level;

    final left = Row(
      children: [
        SizedBox(
          width: wide ? 160 : 120,
          height: wide ? 160 : 120,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: d.accuracy),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              painter: _RingPainter(
                progress: v,
                colors: [AppColors.primary, AppColors.secondary],
                track: AppColors.border.withValues(alpha: 0.7),
                stroke: wide ? 14 : 11,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(v * 100).round()}%',
                        style: _t(wide ? 34 : 28, FontWeight.w800,
                            AppColors.textPrimary)),
                    Text('de acierto',
                        style:
                            _t(12, FontWeight.w400, AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: wide ? 24 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: AppColors.info, size: 14),
                    const SizedBox(width: 4),
                    Text('Nivel $level',
                        style: _t(12, FontWeight.w700, AppColors.info)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(_levelNames[level],
                  style: _t(wide ? 26 : 22, FontWeight.w800,
                      AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  _LegendDot('Correctas', d.correct, AppColors.primary),
                  _LegendDot('Incorrectas', d.wrong, AppColors.error),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: d.total == 0
                      ? Container(color: AppColors.border)
                      : Row(children: [
                          if (d.correct > 0)
                            Expanded(
                                flex: d.correct,
                                child: Container(color: AppColors.primary)),
                          if (d.wrong > 0)
                            Expanded(
                                flex: d.wrong,
                                child: Container(color: AppColors.error)),
                        ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu progreso por niveles',
            style: _t(15, FontWeight.w700, AppColors.textPrimary)),
        const SizedBox(height: 14),
        _LevelTrack(current: level),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nivel actual',
                    style: _t(12, FontWeight.w400, AppColors.textSecondary)),
                Text('$level',
                    style: _t(24, FontWeight.w800, AppColors.textPrimary)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: d.isMax
                        ? Text('Nivel máximo alcanzado',
                            style: _t(12, FontWeight.w700, AppColors.primary))
                        : Text.rich(TextSpan(children: [
                            TextSpan(
                                text: '${(d.progressToNext * 100).round()}% ',
                                style: _t(
                                    12, FontWeight.w800, AppColors.primary)),
                            TextSpan(
                                text: 'hacia ${_levelNames[level + 1]}',
                                style: _t(12, FontWeight.w400,
                                    AppColors.textPrimary)),
                          ])),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: d.progressToNext),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d.isMax
                        ? 'Mantén tu precisión sobre 95%.'
                        : d.total < 10
                            ? 'Responde al menos 10 preguntas para un nivel fiable.'
                            : 'Necesitas ${(_levelThresholds[level + 1] * 100).round()}% de precisión para subir.',
                    style: _t(11, FontWeight.w400, AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    return _Card(
      glow: AppColors.primary,
      padding: EdgeInsets.all(wide ? 24 : 18),
      child: wide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: left),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    color: AppColors.border,
                  ),
                  Expanded(flex: 6, child: right),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 18),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 18),
                right,
              ],
            ),
    );
  }

  Widget _buildStats(_Data d, {required bool wide}) {
    final tiles = [
      _StatTile(
          icon: Icons.check_rounded,
          value: d.correct,
          label: 'Aciertos',
          color: AppColors.primary),
      _StatTile(
          icon: Icons.close_rounded,
          value: d.wrong,
          label: 'Errores',
          color: AppColors.error),
      _StatTile(
          icon: Icons.local_fire_department_rounded,
          value: d.streak,
          label: d.streak == 1 ? 'Día de racha' : 'Días de racha',
          color: _Achievement.orange),
      _StatTile(
          icon: Icons.star_rounded,
          value: d.xp,
          label: 'XP total',
          color: _Achievement.gold),
    ];

    if (wide) {
      return Row(children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: tiles[i]),
        ],
      ]);
    }
    return Column(children: [
      Row(children: [
        Expanded(child: tiles[0]),
        const SizedBox(width: 12),
        Expanded(child: tiles[1]),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: tiles[2]),
        const SizedBox(width: 12),
        Expanded(child: tiles[3]),
      ]),
    ]);
  }

  List<_Insight> _insightsFor(_Data d) {
    final items = <_Insight>[];

    final practiced = _topics
        .where((t) => (d.mastery[t.name] ?? 0) > 0)
        .toList()
      ..sort((a, b) => d.mastery[a.name]!.compareTo(d.mastery[b.name]!));
    final untouched =
        _topics.where((t) => (d.mastery[t.name] ?? 0) == 0).toList();

    if (practiced.isNotEmpty) {
      final weakest = practiced.first;
      final pct = (d.mastery[weakest.name]! * 100).round();
      if (pct < 70) {
        items.add(_Insight(
          Icons.flag_rounded,
          AppColors.warning,
          'Refuerza ${weakest.name}',
          'Es tu tema con menor dominio ($pct%). Dedícale una sesión corta hoy.',
        ));
      }
    }

    if (untouched.isNotEmpty && untouched.length < _topics.length) {
      items.add(_Insight(
        Icons.explore_outlined,
        AppColors.accent,
        untouched.length == 1
            ? 'Te falta 1 tema por explorar'
            : 'Te faltan ${untouched.length} temas por explorar',
        'Empieza por ${untouched.first.name} para completar tu mapa de dominio.',
      ));
    }

    if (d.total >= 10 && d.accuracy >= 0.8) {
      items.add(_Insight(
        Icons.rocket_launch_rounded,
        AppColors.primary,
        '¡Gran precisión!',
        'Estás por encima del 80%. Prueba preguntas más difíciles para subir de nivel.',
      ));
    } else if (d.wrong > 0) {
      items.add(_Insight(
        Icons.replay_rounded,
        AppColors.error,
        'Repasa tus errores',
        'Revisa las preguntas que fallaste y mejora tu precisión.',
      ));
    }

    if (d.streak == 0) {
      items.add(const _Insight(
        Icons.local_fire_department_rounded,
        _Achievement.orange,
        'Empieza una racha hoy',
        'Responde unas preguntas hoy y arranca tu racha diaria.',
      ));
    } else if (d.streak >= 7) {
      items.add(_Insight(
        Icons.local_fire_department_rounded,
        _Achievement.orange,
        '¡${d.streak} días seguidos!',
        'Tu constancia es tu mejor herramienta. No rompas la racha.',
      ));
    }

    if (items.isEmpty) {
      items.add(_Insight(
        Icons.auto_awesome_rounded,
        AppColors.accent,
        'Todo en orden',
        'Sigue practicando para recibir sugerencias personalizadas.',
      ));
    }
    return items;
  }

  Widget _buildInsights(_Data d) {
    final items = _insightsFor(d);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.lightbulb_rounded,
            title: 'Para ti',
            subtitle: 'Sugerencias según tu rendimiento',
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _InsightTile(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTopics(_Data d, {required bool wide}) {
    final values = _topics.map((t) => d.mastery[t.name] ?? 0.0).toList();

    final radar = SizedBox(
      height: wide ? 360 : 320,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          size: Size.infinite,
          painter: _RadarPainter(
            labels: _topics.map((e) => e.name).toList(),
            values: values,
            progress: t,
            color: AppColors.primary,
            colorLight: AppColors.secondary,
            gridColor: AppColors.border,
            textColor: AppColors.textPrimary,
          ),
        ),
      ),
    );

    final list = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _topics.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1, color: AppColors.border.withValues(alpha: 0.6)),
            _TopicRow(topic: _topics[i], mastery: values[i]),
          ],
        ],
      ),
    );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.hub_rounded,
            title: 'Dominio por tema',
            subtitle: 'Tu desempeño en cada área del conocimiento',
          ),
          const SizedBox(height: 12),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: radar),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: list),
              ],
            )
          else ...[
            radar,
            const SizedBox(height: 8),
            list,
          ],
        ],
      ),
    );
  }

  Widget _buildWeekly(_Data d) {
    final now = DateTime.now();
    const labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const areaH = 140.0;

    String key(DateTime x) =>
        '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final count = d.daily[key(day)] ?? 0;
      return (
        label: labels[day.weekday - 1],
        pct: (count / _dailyGoal).clamp(0.0, 1.0),
        today: i == 6,
      );
    });

    Widget yLabel(String s, double top) => Positioned(
          top: top - 7,
          left: 0,
          child: Text(s, style: _t(11, FontWeight.w400, AppColors.textMuted)),
        );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.bar_chart_rounded,
            title: 'Tu actividad semanal',
            subtitle: 'Responde, aprende y mejora',
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: areaH + 14,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      yLabel('100%', 7),
                      yLabel('50%', 7 + areaH / 2),
                      yLabel('0%', 7 + areaH),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GridPainter(
                                color: AppColors.border.withValues(alpha: 0.7)),
                          ),
                        ),
                        Row(
                          children: [
                            for (final day in days)
                              Expanded(
                                child: Center(
                                  child: SizedBox(
                                    width: 26,
                                    height: areaH,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.06),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0, end: day.pct),
                                          duration:
                                              const Duration(milliseconds: 800),
                                          curve: Curves.easeOutCubic,
                                          builder: (_, v, __) => Container(
                                            height: areaH * v,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  AppColors.secondary,
                                                  AppColors.primary
                                                      .withValues(alpha: 0.75),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 40),
              for (final day in days)
                Expanded(
                  child: Center(
                    child: Text(
                      day.label,
                      style: _t(
                        12,
                        day.today ? FontWeight.w800 : FontWeight.w400,
                        day.today
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Meta diaria: $_dailyGoal respuestas',
              style: _t(11, FontWeight.w400, AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildStreaks(_Data d) {
    final current = _StreakCard(
      icon: Icons.local_fire_department_rounded,
      color: _Achievement.orange,
      label: 'Racha actual',
      days: d.streak,
      progress: (d.streak / 7).clamp(0.0, 1.0),
      hint: d.streak == 0
          ? 'Tu racha de aciertos comenzará pronto.'
          : d.streak >= 7
              ? '¡Una semana completa!'
              : 'Te faltan ${7 - d.streak} para completar una semana.',
    );
    final best = _StreakCard(
      icon: Icons.emoji_events_rounded,
      color: _Achievement.gold,
      label: 'Mejor racha',
      days: d.bestStreak,
      progress: (d.bestStreak / 30).clamp(0.0, 1.0),
      hint: 'Tu mejor racha hasta ahora.',
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: current),
        const SizedBox(width: 16),
        Expanded(child: best),
      ],
    );
  }

  Widget _buildMotto() {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.psychology_rounded,
                color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Cada respuesta te acerca a una mejor versión de ti.',
              style: _t(13, FontWeight.w500, AppColors.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Widgets reutilizables
// ─────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.glow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: glow != null ? AppColors.borderAccent : AppColors.border,
        ),
        boxShadow: glow == null
            ? null
            : [
                BoxShadow(
                  color: glow!.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _t(17, FontWeight.w800, AppColors.textPrimary)),
              Text(subtitle,
                  style: _t(12, FontWeight.w400, AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LegendDot(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: _t(13, FontWeight.w400, AppColors.textPrimary)),
        const SizedBox(width: 8),
        Text('$value', style: _t(14, FontWeight.w800, color)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) =>
                      Text('$v', style: _t(24, FontWeight.w800, color)),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _t(13, FontWeight.w400, AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Insight {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  const _Insight(this.icon, this.color, this.title, this.text);
}

class _InsightTile extends StatelessWidget {
  final _Insight i;
  const _InsightTile(this.i);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        color: i.color.withValues(alpha: 0.1),
        borderRadius: radius,
        border: Border.all(color: i.color.withValues(alpha: 0.28)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: i.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(i.icon, color: i.color, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.title,
                                style: _t(14, FontWeight.w700,
                                    AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(i.text,
                                style: _t(12, FontWeight.w400,
                                    AppColors.textSecondary,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final _Topic topic;
  final double mastery;
  const _TopicRow({required this.topic, required this.mastery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(topic.icon, color: topic.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Text(topic.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _t(13, FontWeight.w500, AppColors.textPrimary)),
          ),
          Text('${(mastery * 100).round()}%',
              style: _t(12, FontWeight.w800, AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: mastery),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int days;
  final double progress;
  final String hint;

  const _StreakCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.days,
    required this.progress,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style:
                            _t(12, FontWeight.w400, AppColors.textSecondary)),
                    Text('$days ${days == 1 ? 'día' : 'días'}',
                        style: _t(19, FontWeight.w800, AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(hint,
              style: _t(11, FontWeight.w400, AppColors.textMuted,
                  height: 1.35)),
        ],
      ),
    );
  }
}

class _LevelTrack extends StatelessWidget {
  final int current;
  const _LevelTrack({required this.current});

  @override
  Widget build(BuildContext context) {
    final count = _levelNames.length;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          _node(i),
          if (i < count - 1)
            Expanded(
              child: Container(
                height: 2,
                color: i < current ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }

  Widget _node(int i) {
    final isCurrent = i == current;
    final done = i < current;
    return Container(
      width: isCurrent ? 40 : 34,
      height: isCurrent ? 40 : 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.primary
            : isCurrent
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
        border: Border.all(
          color: done || isCurrent ? AppColors.primary : AppColors.border,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Center(
        child: done
            ? Icon(Icons.check_rounded, size: 18, color: AppColors.surface)
            : Text(
                '$i',
                style: _t(
                  isCurrent ? 16 : 14,
                  FontWeight.w700,
                  isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pintores
// ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.colors,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.max(sweep, 0.01),
          colors: colors,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.colors.length != colors.length ||
      old.colors.first != colors.first ||
      old.colors.last != colors.last;
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final y in [0.0, size.height / 2, size.height]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final double progress;
  final Color color;
  final Color colorLight;
  final Color gridColor;
  final Color textColor;

  _RadarPainter({
    required this.labels,
    required this.values,
    required this.progress,
    required this.color,
    required this.colorLight,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 52;

    Offset point(int i, double r) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor.withValues(alpha: 0.9);

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path()..moveTo(point(0, r).dx, point(0, r).dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(point(i, r).dx, point(i, r).dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, point(i, radius), grid);
    }

    final area = Path();
    for (var i = 0; i < n; i++) {
      final p = point(i, radius * values[i].clamp(0.0, 1.0) * progress);
      i == 0 ? area.moveTo(p.dx, p.dy) : area.lineTo(p.dx, p.dy);
    }
    area.close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawPath(
      area,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = colorLight,
    );

    for (var i = 0; i < n; i++) {
      final p = point(i, radius * values[i].clamp(0.0, 1.0) * progress);
      canvas.drawCircle(p, 4, Paint()..color = colorLight);
    }

    for (var i = 0; i < n; i++) {
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
                text: '${labels[i]}\n',
                style: _t(11, FontWeight.w500, textColor)),
            TextSpan(
                text: '${(values[i] * 100).round()}%',
                style: _t(11, FontWeight.w700, color)),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final p = point(i, radius + 30);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.color != color ||
      old.colorLight != colorLight ||
      old.gridColor != gridColor ||
      old.textColor != textColor;
}