// lib/features/achievements/widgets/top_bar.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';

class TopBar extends StatelessWidget {
  final AchievementService service;
  final EdgeInsets padding;

  const TopBar({
    super.key,
    required this.service,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
                Text(
                  '🏅 Tus Logros',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.unlockedCount} de ${service.totalCount} desbloqueados',
                  // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
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