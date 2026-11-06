import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';
import 'medal.dart';
import '../models/achievement_model.dart';

class NextUpCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementService service;
  final VoidCallback onTap;

  const NextUpCard({
    super.key,
    required this.achievement,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final p = service.progressOf(a);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 270,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: a.color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Medal(achievement: a, unlocked: false, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(a.color),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${service.currentOf(a)} / ${a.target}  ·  ${(p * 100).round()}%',
                    style: TextStyle(
                      color: a.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}