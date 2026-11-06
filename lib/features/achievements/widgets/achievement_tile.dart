import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';
import 'medal.dart';
import '../models/achievement_model.dart';

class AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementService service;
  final VoidCallback onTap;

  const AchievementTile({
    super.key,
    required this.achievement,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final unlocked = service.isUnlocked(a.id);
    final progress = service.progressOf(a);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          gradient: unlocked
              ? LinearGradient(
                  colors: [a.color.withValues(alpha: 0.2), AppColors.surfaceCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked ? a.color.withValues(alpha: 0.6) : AppColors.border,
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: unlocked
              ? [BoxShadow(color: a.color.withValues(alpha: 0.22), blurRadius: 14, offset: const Offset(0, 5))]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Medal(achievement: a, unlocked: unlocked, size: 52),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: a.rarity.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.rarity.label.toUpperCase(),
                    style: TextStyle(
                      color: a.rarity.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unlocked ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.75),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
            Text(
              a.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
            const Spacer(),
            if (unlocked)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Logrado · +${a.xp} XP',
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(a.color),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
                  Text(
                    '${service.currentOf(a)} / ${a.target}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: a.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}