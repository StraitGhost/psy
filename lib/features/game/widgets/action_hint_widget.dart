import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Barra inferior: 💡 texto de pista ............ [botón de acción]
class ActionHintWidget extends StatelessWidget {
  const ActionHintWidget({
    super.key,
    required this.hint,
    this.action,
  });

  final String hint;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.55)),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 15, 
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            action!,
          ],
        ],
      ),
    );
  }
}