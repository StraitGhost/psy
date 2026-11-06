import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart'; // ✅ Corregido: 3 niveles hacia arriba

/// Panel base con borde y brillo suave. Lo usan casi todos los widgets.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.borderColor,
    this.gradient,
    this.glow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Gradient? gradient;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.border;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.2),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: (borderColor ?? AppColors.primary).withValues(alpha: 0.28),
                  blurRadius: 18,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}