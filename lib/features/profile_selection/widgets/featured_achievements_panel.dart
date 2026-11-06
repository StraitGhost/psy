import 'package:flutter/material.dart';
import 'package:psy/features/profile_selection/profile_panel.dart';
import '../../../core/theme/app_colors.dart';
import '../../achievements/models/achievement_model.dart';
import '../../../services/achievement_service.dart';

class FeaturedAchievementsPanel extends StatelessWidget {
  const FeaturedAchievementsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AchievementService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        // Obtenemos los IDs de los slots (pueden estar vacíos '')
        final slot1Id = service.stats.featuredSlot1;
        final slot2Id = service.stats.featuredSlot2;
        final slot3Id = service.stats.featuredSlot3;

        return ProfilePanel(
          icon: Icons.military_tech_rounded,
          title: 'Logros Destacados',
          subtitle: 'Tus mayores orgullos. Toca para editar.',
          trailing: IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            color: AppColors.primary,
            onPressed: () {
              // Aquí puedes navegar a la pantalla de logros para que los edite
              // Navigator.push(context, MaterialPageRoute(...));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abre la pantalla de Logros para editarlos')),
              );
            },
          ),
          child: Row(
            children: [
              _buildSlot(context, service, slot1Id, 1),
              const SizedBox(width: 12),
              _buildSlot(context, service, slot2Id, 2),
              const SizedBox(width: 12),
              _buildSlot(context, service, slot3Id, 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlot(
    BuildContext context,
    AchievementService service,
    String achievementId,
    int slotNumber,
  ) {
    // Si el slot está vacío, mostramos un placeholder
    if (achievementId.isEmpty) {
      return Expanded(
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 28),
              const SizedBox(height: 4),
              Text(
                'Slot $slotNumber',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    // Si tiene un logro, lo buscamos
    final achievement = getAchievementById(achievementId);
    if (achievement == null) {
      return const SizedBox.shrink(); // Por seguridad si no se encuentra
    }

    final isUnlocked = service.isUnlocked(achievement.id);
    final rarityColor = achievement.rarity.color;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Opcional: Mostrar el DetailSheet al tocar el logro destacado
          // showModalBottomSheet(...)
        },
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: rarityColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rarityColor.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono o Emoji del logro
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  color: rarityColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              // Título del logro (truncado si es muy largo)
              Text(
                achievement.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}