import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/achievement_service.dart';
import 'medal.dart';
import '../models/achievement_model.dart';

class DetailSheet extends StatelessWidget {
  final Achievement achievement;
  final AchievementService service;

  const DetailSheet({
    super.key,
    required this.achievement,
    required this.service,
  });

  String _date(DateTime d) {
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final unlocked = service.isUnlocked(a.id);
    final at = service.unlockedAt(a.id);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Medal(achievement: a, unlocked: unlocked, size: 110),
          const SizedBox(height: 16),
          Text(
            a.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: a.rarity.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${a.rarity.label} · +${a.xp} XP',
              style: TextStyle(
                color: a.rarity.color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          
          // ✅ NUEVO: Botón para agregar a destacados (solo si está desbloqueado)
          if (unlocked) ...[
            GestureDetector(
              onTap: () => _showFeaturedDialog(context, a.id),
              child: _buildFeaturedButton(a.id),
            ),
            const SizedBox(height: 20),
          ],

          if (unlocked && at != null)
            Text(
              '🎉 Conseguido el ${_date(at)}',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: service.progressOf(a),
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(a.color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${service.currentOf(a)} de ${a.target}',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget del botón con cambio de color dinámico
  Widget _buildFeaturedButton(String achievementId) {
    final isFeatured = service.isFeatured(achievementId);
    final slotIndex = service.getFeaturedSlotIndex(achievementId);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFeatured 
            ? AppColors.primary.withValues(alpha: 0.12) 
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFeatured 
              ? AppColors.primary 
              : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFeatured ? Icons.star : Icons.star_border,
            color: isFeatured ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFeatured 
                      ? '⭐ En destacados (Slot ${slotIndex + 1})'
                      : 'Agregar a destacados',
                  style: TextStyle(
                    color: isFeatured 
                        ? AppColors.primary 
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (!isFeatured)
                  Text(
                    'Toca para seleccionar un slot',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isFeatured ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Diálogo para elegir en qué slot poner el logro
  void _showFeaturedDialog(BuildContext context, String achievementId) {
    final currentSlot = service.getFeaturedSlotIndex(achievementId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⭐ Agregar a destacados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona un slot para este logro:'),
            const SizedBox(height: 16),
            ...List.generate(3, (index) {
              final isSelected = currentSlot == index;
              final achievementInSlot = service.featuredAchievements.length > index
                  ? service.featuredAchievements[index]
                  : '';
              
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                title: Text('Slot ${index + 1}'),
                subtitle: achievementInSlot.isNotEmpty
                    ? const Text('Ocupado por otro logro (se reemplazará)')
                    : const Text('Disponible'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await service.addToFeaturedSlot(achievementId, index);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Logro agregado al Slot ${index + 1}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          if (currentSlot != -1)
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await service.removeFromFeaturedSlot(currentSlot);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Logro removido de destacados'),
                    ),
                  );
                }
              },
              child: const Text('Remover'),
            ),
        ],
      ),
    );
  }
}