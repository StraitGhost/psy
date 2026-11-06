// lib/widgets/stats_row.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/learning_progress_service.dart';

class StatsRow extends StatefulWidget {
  final int completedCases;
  final int totalCases;
  final int accuracy;
  final int errors;
  final int studyTimeMinutes;
  final String profileId;

  const StatsRow({
    super.key,
    required this.completedCases,
    required this.totalCases,
    required this.accuracy,
    required this.errors,
    required this.studyTimeMinutes,
    required this.profileId,
  });

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  final LearningProgressService _service = LearningProgressService();
  late Stream<int> _mistakesStream;

  @override
  void initState() {
    super.initState();
    _mistakesStream = _service.getMistakesCount();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.folder_outlined,
            label: 'Casos completados',
            value: '${widget.completedCases} / ${widget.totalCases}',
            // ✅ MEJORADO: Usa color primario del agente
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            label: 'Aciertos',
            value: '${widget.accuracy}%',
            // ✅ MEJORADO: Usa color de éxito
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<int>(
            stream: _mistakesStream,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data! : widget.errors;
              return _StatCard(
                icon: Icons.error_outline,
                label: 'Errores',
                value: '$count',
                // ✅ MEJORADO: Usa color de error
                color: AppColors.error,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            label: 'Tiempo',
            value: _formatTime(widget.studyTimeMinutes),
            // ✅ MEJORADO: Usa color de información/accento
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}