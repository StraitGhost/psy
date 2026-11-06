import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'question_card.dart';

/// Chips (tipo + tema) y enunciado.
///  • large: true  → tarjeta ancha con texto más grande (pantallas anchas).
///  • boxed: true/false → versión compacta (móvil).
class QuestionHero extends StatelessWidget {
  const QuestionHero({
    super.key,
    required this.typeLabel,
    required this.typeIcon,
    required this.topic,
    required this.topicIcon,
    required this.text,
    this.artIcon = Icons.psychology_outlined,
    this.boxed = true,
    this.large = false,
  });

  final String typeLabel;
  final IconData typeIcon;
  final String topic;
  final IconData topicIcon;
  final String text;
  final IconData artIcon;
  final bool boxed;
  final bool large;

  Widget _chips() => Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _Chip(icon: typeIcon, label: typeLabel),
          _Chip(icon: topicIcon, label: 'Tema: $topic'),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerRight,
            child: _HeroArt(
              icon: artIcon,
              size: large ? 100 : (boxed ? 78 : 58),
              boxed: boxed || large,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: large ? 150 : (boxed ? 84 : 64)),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: large ? 96 : (boxed ? 64 : 44)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: large ? 22 : (boxed ? 16.5 : 15),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chips(),
        SizedBox(height: large ? 16 : 12),
        if (boxed || large)
          QuestionCard(
            padding: large
                ? const EdgeInsets.symmetric(horizontal: 28, vertical: 22)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: body,
          )
        else
          Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: body),
      ],
    );
  }
}

/// Ícono con halo y red de nodos detrás.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.icon, required this.size, required this.boxed});

  final IconData icon;
  final double size;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.45,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _NetworkPainter(strong: boxed)),
          ),
          Icon(
            icon,
            size: size * 0.72,
            color: AppColors.primary.withValues(alpha: boxed ? 0.6 : 0.35),
            shadows: [
              Shadow(color: AppColors.primary.withValues(alpha: 0.9), blurRadius: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  const _NetworkPainter({required this.strong});

  final bool strong;

  static const _points = [
    Offset(0.08, 0.22),
    Offset(0.30, 0.04),
    Offset(0.72, 0.08),
    Offset(0.95, 0.36),
    Offset(0.86, 0.82),
    Offset(0.50, 0.97),
    Offset(0.14, 0.78),
    Offset(0.02, 0.50),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = strong ? 1.0 : 0.6;
    final line = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.30 * k)
      ..strokeWidth = 1;
    final dot = Paint()..color = AppColors.info.withValues(alpha: 0.7 * k);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.primary.withValues(alpha: 0.22 * k);

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.height * 0.47, ring);

    Offset? previous;
    for (final p in _points) {
      final o = Offset(p.dx * size.width, p.dy * size.height);
      canvas.drawLine(o, center, line);
      if (previous != null) canvas.drawLine(previous, o, line);
      canvas.drawCircle(o, 2.5, dot);
      previous = o;
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) =>
      oldDelegate.strong != strong;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.25),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.7)),
            ),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}