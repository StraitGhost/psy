import 'package:flutter/material.dart';
import '../../../../services/achievement_service.dart';

class LevelRing extends StatelessWidget {
  final AchievementService service;
  final double size;

  const LevelRing({
    super.key,
    required this.service,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.77;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: service.xpInLevel / AchievementService.xpPerLevel),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NIVEL',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                Text('${service.level}',
                    style: TextStyle(
                        color: Colors.white, fontSize: size * 0.3, fontWeight: FontWeight.w900, height: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}