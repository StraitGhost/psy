// lib/widgets/level_panel.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LevelPanel extends StatelessWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final int currentLevel;
  final String levelName;

  const LevelPanel({
    super.key,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.currentLevel,
    required this.levelName,
  });

  double get _accuracy {
    final total = correctAnswers + wrongAnswers;
    if (total == 0) return 0.0;
    return (correctAnswers / total).clamp(0.0, 1.0);
  }

  String get _nextLevelName {
    if (currentLevel >= 5) return 'Maestro';
    switch (currentLevel + 1) {
      case 1: return 'Intermedio';
      case 2: return 'Avanzado';
      case 3: return 'Experto';
      case 4: return 'Maestro';
      default: return 'Siguiente nivel';
    }
  }

  // ✅ MEJORADO: Usa el color primario del agente con variaciones
  Color get _levelColor {
    // Si es nivel máximo (Maestro), usa dorado o el acento del agente
    if (currentLevel >= 5) return AppColors.warning;
    
    // Para otros niveles, usamos el primario del agente
    return AppColors.primary;
  }

  // ✅ MEJORADO: Gradiente dinámico para el icono de nivel
  LinearGradient get _levelGradient => LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
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
            'Tu nivel actual',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // ✅ MEJORADO: Icono de nivel con gradiente del agente
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _levelGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  currentLevel >= 5 ? Icons.emoji_events : Icons.trending_up,
                  color: AppColors.textOnPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Información del nivel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelName,
                      style: TextStyle(
                        color: _levelColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nivel $currentLevel',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Barra de progreso hacia el siguiente nivel
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso al siguiente nivel',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${(_accuracy * 100).round()}%',
                    style: TextStyle(
                      color: _levelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _accuracy,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(_levelColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentLevel >= 5
                    ? '¡Has alcanzado el nivel máximo!'
                    : 'Necesitas ${((_accuracy * 100).round() >= 70 ? "menos" : "más")} aciertos para subir a $_nextLevelName',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}