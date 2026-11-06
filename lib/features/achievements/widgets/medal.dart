import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/achievement_model.dart';

class Medal extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final double size;

  const Medal({
    super.key,
    required this.achievement,
    required this.unlocked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? LinearGradient(
                colors: [a.color, a.color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: unlocked ? null : AppColors.border.withValues(alpha: 0.5),
        border: Border.all(color: unlocked ? a.rarity.color : AppColors.border, width: 2.5),
        boxShadow: unlocked ? [BoxShadow(color: a.color.withValues(alpha: 0.5), blurRadius: 14)] : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(a.icon, color: unlocked ? Colors.white : Colors.grey.shade600, size: size * 0.5),
          if (!unlocked)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFF334155), shape: BoxShape.circle),
                child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 11),
              ),
            ),
        ],
      ),
    );
  }
}