// lib/widgets/progress_panel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_preferences.dart';

double _asDouble(dynamic v) => v is num ? v.toDouble() : 0.0;

Map<String, double> _parseMastery(dynamic raw) {
  if (raw is! Map) return {};
  return raw.map((k, v) =>
      MapEntry(k.toString(), _asDouble(v).clamp(0.0, 1.0).toDouble()));
}

/// Panel de progreso general.
/// Carga sus propios datos desde Firestore (usuarios/{uid}), igual que
/// ProgressScreen. Los parámetros solo se usan como respaldo.
class ProgressPanel extends StatefulWidget {
  final int completedCases;
  final int totalCases;
  final Map<String, double> topicMastery;

  const ProgressPanel({
    super.key,
    this.completedCases = 0,
    this.totalCases = 0,
    this.topicMastery = const {},
  });

  // Los 10 temas (mismos nombres que en ProgressScreen).
  // El icono usa el color propio del tema; las barras usan el color del agente.
  static const List<({String name, IconData icon, Color color})> _topics = [
    (name: 'Conciencia', icon: Icons.wb_sunny, color: Color(0xFF00B4DB)),
    (name: 'Orientación', icon: Icons.explore, color: Color(0xFF11998E)),
    (name: 'Atención', icon: Icons.center_focus_weak, color: Color(0xFFFF512F)),
    (name: 'Memoria', icon: Icons.memory, color: Color(0xFF8E2DE2)),
    (name: 'Percepción', icon: Icons.visibility, color: Color(0xFF00C6FF)),
    (name: 'Pensamiento', icon: Icons.psychology, color: Color(0xFFDA22FF)),
    (name: 'Sueño', icon: Icons.nightlight_round, color: Color(0xFF2193B0)),
    (name: 'Apetito', icon: Icons.restaurant, color: Color(0xFF56AB2F)),
    (name: 'Sexualidad', icon: Icons.favorite, color: Color(0xFFFF9A9E)),
    (name: 'Síndromes', icon: Icons.medical_services, color: Color(0xFF536976)),
  ];

  @override
  State<ProgressPanel> createState() => _ProgressPanelState();
}

class _ProgressPanelState extends State<ProgressPanel> {
  /// Alto visible de la lista de temas (el resto se desplaza).
  static const double _listHeight = 230;

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return ValueListenableBuilder<String>(
      valueListenable: ThemePreferences.instance.themeMode,
      builder: (context, _, __) {
        if (uid == null) {
          return _buildPanel(widget.topicMastery, widget.completedCases);
        }
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            var mastery = widget.topicMastery;
            var completed = widget.completedCases;

            if (snap.hasData && snap.data!.exists) {
              final m = snap.data!.data() as Map<String, dynamic>? ?? {};
              final progress = m['progress'] is Map ? m['progress'] as Map : {};

              // topicMastery en la raíz o dentro de 'progress' (igual que ProgressScreen)
              final parsed =
                  _parseMastery(m['topicMastery'] ?? progress['topicMastery']);
              if (parsed.isNotEmpty) mastery = parsed;

              // casos completados (lista o número)
              if (completed == 0) {
                final raw = m['completedCases'] ?? progress['completedCases'];
                if (raw is List) {
                  completed = raw.length;
                } else if (raw is num) {
                  completed = raw.toInt();
                }
              }
            }
            return _buildPanel(mastery, completed);
          },
        );
      },
    );
  }

  Widget _buildPanel(Map<String, double> mastery, int completed) {
    // Progreso general = promedio del dominio de los 10 temas
    // (los temas sin practicar cuentan como 0%).
    final topicsList = ProgressPanel._topics;
    final general = (topicsList.fold<double>(
                0.0, (sum, t) => sum + (mastery[t.name] ?? 0.0).clamp(0.0, 1.0)) /
            topicsList.length)
        .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu progreso general',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: general,
                        strokeWidth: 8,
                        backgroundColor: AppColors.border,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Text(
                      '${(general * 100).round()}%',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: _listHeight,
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.only(right: 12),
                      physics: const BouncingScrollPhysics(),
                      children: ProgressPanel._topics.map((topic) {
                    final value = (mastery[topic.name] ?? 0.0).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(topic.icon, color: topic.color, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  topic.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${(value * 100).round()}%',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: AppColors.border,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}