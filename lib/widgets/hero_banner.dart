// lib/features/home/widgets/hero_banner.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // ✅ MEJORADO: Gradiente dinámico basado en el agente
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.1),
            AppColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Bienvenido a PsyCase',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Explora, analiza\ny comprende.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sumérgete en casos clínicos reales, investiga síntomas,\nanaliza patrones y descubre los síndromes de la\nPsicopatología.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Imagen de cerebro
          SizedBox(
            width: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Icon(
                  Icons.psychology,
                  size: 180,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, color: AppColors.primary, size: 24),
                const SizedBox(height: 12),
                Text(
                  '"La observación, el análisis y la empatía son herramientas fundamentales en la comprensión del comportamiento humano."',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
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