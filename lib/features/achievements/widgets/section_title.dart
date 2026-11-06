// lib/features/achievements/widgets/section_title.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';
import '../models/achievement_model.dart';

class SectionTitle extends StatelessWidget {
  final AchievementCategory category;
  final AchievementService service;

  const SectionTitle({
    super.key,
    required this.category,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final list = kAchievements.where((a) => a.category == category);
    final done = list.where((a) => service.isUnlocked(a.id)).length;
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
          Text(
            '${category.emoji} ${category.label}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$done/${list.length}',
              // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}