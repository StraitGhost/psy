import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'medal.dart';
import '../models/achievement_model.dart';

Future<void> showAchievementUnlocked(BuildContext context, Achievement a) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Logro',
    barrierColor: Colors.black.withValues(alpha: 0.7),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: animation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: a.rarity.color, width: 2),
                  boxShadow: [BoxShadow(color: a.color.withValues(alpha: 0.6), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '¡LOGRO DESBLOQUEADO!',
                      style: TextStyle(
                        color: a.rarity.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Medal(achievement: a, unlocked: true, size: 100),
                    const SizedBox(height: 16),
                    // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
                    Text(
                      a.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
                    Text(
                      a.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '+${a.xp} XP',
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: a.color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('¡Genial!', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}