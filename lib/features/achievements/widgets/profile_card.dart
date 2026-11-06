import 'package:flutter/material.dart';
import '../../../../services/achievement_service.dart';
import 'level_ring.dart';
import 'mini_stat.dart';

const _kGradient = LinearGradient(
  colors: [Color(0xFF5B4BFF), Color(0xFF2D8CFF), Color(0xFF22D3EE)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ProfileCard extends StatelessWidget {
  final AchievementService service;
  final bool compact;

  const ProfileCard({
    super.key,
    required this.service,
    required this.compact,
  });

  Widget _info(CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(service.levelTitle,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('${service.xpInLevel} / ${AchievementService.xpPerLevel} XP para el nivel ${service.level + 1}',
            textAlign: align == CrossAxisAlignment.center ? TextAlign.center : TextAlign.start,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(end: service.completion),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(service.completion * 100).round()}% de la colección',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: _kGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x445B4BFF), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          if (compact)
            Row(
              children: [
                LevelRing(service: service, size: 84),
                const SizedBox(width: 16),
                Expanded(child: _info(CrossAxisAlignment.start)),
              ],
            )
          else ...[
            LevelRing(service: service, size: 112),
            const SizedBox(height: 14),
            _info(CrossAxisAlignment.center),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              MiniStat(value: '${service.unlockedCount}', label: 'Logrados'),
              const SizedBox(width: 8),
              MiniStat(value: '${service.totalCount - service.unlockedCount}', label: 'Pendientes'),
              const SizedBox(width: 8),
              MiniStat(value: '${service.totalXp}', label: 'XP total'),
            ],
          ),
        ],
      ),
    );
  }
}