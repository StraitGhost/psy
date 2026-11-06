// lib/features/home/widgets/home_section_title.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textPrimary es dinámico
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          // ✅ CORREGIDO: Se quitó 'const' porque AppColors.textMuted es dinámico
          Text(
            subtitle!,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}