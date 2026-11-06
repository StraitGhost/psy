import 'package:flutter/material.dart';

import 'game_theme.dart';
import 'question_card.dart';

/// Retroalimentación al responder:
///
///  1. Alerta arriba  → roja "¡Respuesta incorrecta!" (con la respuesta correcta
///                      en [detail]) o verde "¡Correcto!" (con [starsEarned]).
///  2. Explicación    → tarjeta azul justo debajo.
class ExplanationWidget extends StatelessWidget {
  const ExplanationWidget({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.detail,
    this.starsEarned = 0,
  });

  final bool isCorrect;
  final String explanation;

  /// Solo se muestra cuando la respuesta es incorrecta.
  /// Ej.: "Respuesta correcta: Falso".
  final String? detail;

  /// Solo se muestra cuando la respuesta es correcta.
  final int starsEarned;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Reveal(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          child: _AlertBanner(
            isCorrect: isCorrect,
            detail: detail,
            starsEarned: starsEarned,
          ),
        ),
        const SizedBox(height: 12),
        _Reveal(
          duration: const Duration(milliseconds: 800),
          curve: const Interval(0.4, 1, curve: Curves.easeOut),
          child: _ExplanationCard(text: explanation),
        ),
      ],
    );
  }
}

/// Aparece con fundido + pequeño desplazamiento y "rebote".
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.child,
    required this.duration,
    required this.curve,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      child: child,
      builder: (context, v, child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - v)),
            child: child,
          ),
        );
      },
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.isCorrect,
    required this.detail,
    required this.starsEarned,
  });

  final bool isCorrect;
  final String? detail;
  final int starsEarned;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? GameColors.success : GameColors.danger;
    final subtitle = isCorrect ? null : detail;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.o(0.28), color.o(0.10)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [BoxShadow(color: color.o(0.4), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.o(0.6), blurRadius: 12)],
            ),
            child: Icon(
              isCorrect ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '¡Correcto!' : '¡Respuesta incorrecta!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.o(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCorrect && starsEarned > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.o(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: GameColors.gold, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    '+$starsEarned',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return QuestionCard(
      glow: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameColors.glow.o(0.16),
              border: Border.all(color: GameColors.glow.o(0.6)),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                size: 16, color: GameColors.cyan),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explicación',
                  style: TextStyle(
                    color: GameColors.cyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.o(0.92),
                    fontSize: 13.5,
                    height: 1.45,
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
