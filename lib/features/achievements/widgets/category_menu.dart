import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';
import '../models/achievement_model.dart';

class CategoryMenu extends StatelessWidget {
  final AchievementService service;
  final dynamic selected;
  final ValueChanged<dynamic> onSelect;

  const CategoryMenu({
    super.key,
    required this.service,
    required this.selected,
    required this.onSelect,
  });

  Widget _item(String label, String count, bool isSel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF7568FF).withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSel ? const Color(0xFF7568FF).withValues(alpha: 0.6) : Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: isSel ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14)),
                ),
                Text(count,
                    style: TextStyle(
                        color: isSel ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _item('✨ Todos', '${service.unlockedCount}/${service.totalCount}', selected == null, () => onSelect(null)),
          for (final c in AchievementCategory.values)
            _item(
              '${c.emoji} ${c.label}',
              '${kAchievements.where((a) => a.category == c && service.isUnlocked(a.id)).length}/${kAchievements.where((a) => a.category == c).length}',
              selected == c,
              () => onSelect(c),
            ),
        ],
      ),
    );
  }
}