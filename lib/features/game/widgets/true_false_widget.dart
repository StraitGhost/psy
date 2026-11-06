import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TrueFalseWidget extends StatelessWidget {
  const TrueFalseWidget({
    super.key,
    required this.onSelected,
    this.selected,
    this.correctAnswer,
    this.locked = false,
  });

  final ValueChanged<bool> onSelected;
  final bool? selected;
  final bool? correctAnswer;
  final bool locked;

  Color? _resultColor(bool value) {
    if (!locked || correctAnswer == null) return null;
    if (value == correctAnswer) return AppColors.success;
    if (selected == value) return AppColors.error;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // >= 900: lado a lado y grandes | 560..900: apiladas grandes
        // 440..560: lado a lado compactas | < 440: apiladas compactas
        final tall = c.maxWidth >= 560;
        final sideBySide = c.maxWidth >= 900 || (c.maxWidth >= 440 && !tall);

        final trueCard = _ChoiceCard(
          title: 'Verdadero',
          subtitle: 'La afirmación es correcta',
          icon: Icons.check_rounded,
          accent: AppColors.success,
          tall: tall,
          isSelected: selected == true,
          dimmed: locked && selected != true && correctAnswer != true,
          resultColor: _resultColor(true),
          onTap: locked ? null : () => onSelected(true),
        );
        final falseCard = _ChoiceCard(
          title: 'Falso',
          subtitle: 'La afirmación es incorrecta',
          icon: Icons.close_rounded,
          accent: AppColors.error,
          tall: tall,
          isSelected: selected == false,
          dimmed: locked && selected != false && correctAnswer != false,
          resultColor: _resultColor(false),
          onTap: locked ? null : () => onSelected(false),
        );

        if (sideBySide) {
          return Row(children: [
            Expanded(child: trueCard),
            const SizedBox(width: 14),
            Expanded(child: falseCard),
          ]);
        }
        return Column(children: [
          trueCard,
          SizedBox(height: tall ? 20 : 12),
          falseCard,
        ]);
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tall,
    required this.isSelected,
    required this.dimmed,
    required this.onTap,
    this.resultColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool tall;
  final bool isSelected;
  final bool dimmed;
  final Color? resultColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = resultColor ?? (isSelected ? Colors.white : null);
    final iconBox = tall ? 76.0 : 56.0;

    return AnimatedOpacity(
      opacity: dimmed ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: MouseRegion(
        cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: BoxConstraints(minHeight: tall ? 150 : 104),
            padding: EdgeInsets.symmetric(
              horizontal: tall ? 28 : 16,
              vertical: tall ? 24 : 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.85),
                  accent.withValues(alpha: 0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(tall ? 26 : 20),
              border: Border.all(
                color: highlight ?? accent.withValues(alpha: 0.9),
                width: highlight != null ? 2.5 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: (resultColor ?? accent)
                      .withValues(alpha: isSelected ? 0.55 : 0.28),
                  blurRadius: isSelected ? 28 : 16,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                  ),
                  child: Icon(icon, color: Colors.white, size: iconBox * 0.58),
                ),
                SizedBox(width: tall ? 24 : 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tall ? 30 : 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: tall ? 15 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: tall ? 34 : 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}