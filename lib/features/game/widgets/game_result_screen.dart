import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'next_button_widget.dart';
import 'question_card.dart';

/// Pantalla de resultados al terminar el juego.
class GameResultScreen extends StatelessWidget {
  const GameResultScreen({
    super.key,
    required this.correct,
    required this.total,
    required this.stars,
    this.title = 'Casos Clínicos',
    this.onRetry,
    this.onExit,
  });

  final int correct;
  final int total;
  final int stars;
  final String title;
  final VoidCallback? onRetry;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (correct * 100 / total).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Trofeo con gradiente y brillo del agente
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.surface, AppColors.surfaceCard],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.3),
                            blurRadius: 32,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 64, 
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡Completado!',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    QuestionCard(
                      glow: true,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                            value: '$correct/$total',
                            label: 'Correctas',
                          ),
                          _Stat(
                            icon: Icons.percent_rounded,
                            color: AppColors.primary, // ✅ Usa el color del agente
                            value: '$percent%',
                            label: 'Acierto',
                          ),
                          _Stat(
                            icon: Icons.star_rounded,
                            color: AppColors.warning,
                            value: '$stars',
                            label: 'Estrellas',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    NextButtonWidget(
                      label: 'Reintentar',
                      icon: Icons.refresh_rounded,
                      iconLeading: true,
                      onPressed: onRetry,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onExit,
                      child: Text(
                        'Salir',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}