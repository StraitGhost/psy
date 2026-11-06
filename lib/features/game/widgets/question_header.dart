import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart'; // ✅ Corregido: 3 niveles hacia arriba

/// Barra superior: ← Título ........ 1/5  ★ 120  Nivel: Principiante  [icono]
class QuestionHeader extends StatelessWidget {
  const QuestionHeader({
    super.key,
    required this.title,
    required this.current,
    required this.total,
    this.stars = 0,
    this.level = 'Principiante',
    this.onBack,
    this.onMenu,
  });

  static const double titleInset = 40;

  final String title;
  final int current;
  final int total;
  final int stars;
  final String level;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLevel = constraints.maxWidth > 430;
        return Row(
          children: [
            InkResponse(
              onTap: onBack,
              radius: 22,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                    const SizedBox(height: 2),
                    Container(
                      width: 16,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$current/$total',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 4),
            Text(
              '$stars',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showLevel) ...[
              const SizedBox(width: 16),
              Text(
                'Nivel: $level',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(width: 12),
            InkResponse(
              onTap: onMenu,
              radius: 20,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.bookmark_border_rounded, color: AppColors.textMuted, size: 20),
              ),
            ),
          ],
        );
      },
    );
  }
}